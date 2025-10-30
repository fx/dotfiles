#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_test() { echo -e "${YELLOW}TEST:${NC} $1"; }
print_pass() { echo -e "${GREEN}✓${NC} $1"; }
print_fail() { echo -e "${RED}✗${NC} $1"; }

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running or you don't have permission to access it."
    echo "Try one of:"
    echo "  - sudo service docker start"
    echo "  - sudo ./test/test-dotfiles.sh"
    echo "  - sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

IMAGE="ghcr.io/fx/docker/devcontainer:latest"

# Pull the image
echo "Pulling Docker image: $IMAGE"
docker pull "$IMAGE"

# Test 1: Non-Coder Environment
print_test "Non-Coder Environment (direct symlink from dotfiles)"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    "$IMAGE" \
    bash -c '
        # Install dotfiles in non-Coder mode
        export CODER=""
        bash install.sh default 2>&1 | grep -v "git config" || true

        # Verify ~/.claude exists and is a symlink
        if [ -L "$HOME/.claude" ]; then
            echo "✓ ~/.claude is a symlink"
        else
            echo "✗ ~/.claude is not a symlink"
            exit 1
        fi

        # Verify all content is accessible
        if [ -d "$HOME/.claude/agents" ]; then
            echo "✓ agents directory accessible"
        else
            echo "✗ agents not accessible"
            exit 1
        fi
    '

print_pass "Non-Coder test passed"

# Test 2: Coder Environment (fresh install)
print_test "Coder Environment - Fresh Install"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    -e CODER=true \
    --tmpfs /shared:rw,exec \
    "$IMAGE" \
    bash -c '
        # Install dotfiles in Coder mode
        bash install.sh default 2>&1 | grep -v "git config" || true

        # Verify /shared was seeded
        if [ -d "/shared/home/default/.claude" ]; then
            echo "✓ /shared/home/default/.claude seeded"
        else
            echo "✗ /shared not seeded"
            exit 1
        fi

        # Verify ~/.claude is a symlink to /shared
        if [ -L "$HOME/.claude" ]; then
            echo "✓ ~/.claude is a symlink"
            target=$(readlink "$HOME/.claude")
            if [[ "$target" == *"/shared/"* ]]; then
                echo "✓ ~/.claude points to /shared"
            else
                echo "✗ ~/.claude does not point to /shared"
                exit 1
            fi
        else
            echo "✗ ~/.claude is not a symlink"
            exit 1
        fi
    '

print_pass "Coder fresh install test passed"

# Test 3: Coder Environment (existing ~/.claude)
print_test "Coder Environment - Existing ~/.claude"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    -e CODER=true \
    --tmpfs /shared:rw,exec \
    "$IMAGE" \
    bash -c '
        # Create existing ~/.claude with user content
        mkdir -p "$HOME/.claude"
        echo "user_settings" > "$HOME/.claude/settings.json"
        echo "user_custom" > "$HOME/.claude/custom.txt"

        # Install mise and chezmoi first
        curl -sSL https://mise.jdx.dev/install.sh | sh >/dev/null 2>&1
        export PATH="$HOME/.local/bin:$PATH"
        eval "$(mise activate bash)"
        mise use -g chezmoi@latest >/dev/null 2>&1

        # Mark workspace as safe directory for Git
        git config --global --add safe.directory /workspace

        # Use local repository as source (not GitHub)
        mise exec -- chezmoi init --apply --promptString profile=default /workspace 2>&1 | grep -v "git config" || true

        # Verify ~/.claude is NOT a symlink (real directory)
        if [ ! -L "$HOME/.claude" ] && [ -d "$HOME/.claude" ]; then
            echo "✓ ~/.claude is a real directory"
        else
            echo "✗ ~/.claude is not a real directory"
            exit 1
        fi

        # Verify user files are preserved
        if [ -f "$HOME/.claude/settings.json" ]; then
            echo "✓ User settings.json preserved"
        else
            echo "✗ User settings.json missing"
            exit 1
        fi

        # Verify subdirectories are symlinks
        if [ -L "$HOME/.claude/agents" ]; then
            echo "✓ agents is a symlink"
        else
            echo "✗ agents is not a symlink"
            exit 1
        fi

        if [ -L "$HOME/.claude/commands" ]; then
            echo "✓ commands is a symlink"
        else
            echo "✗ commands is not a symlink"
            exit 1
        fi

        if [ -L "$HOME/.claude/skills" ]; then
            echo "✓ skills is a symlink"
        else
            echo "✗ skills is not a symlink"
            exit 1
        fi

        # Verify CLAUDE.md is a symlink
        if [ -L "$HOME/.claude/CLAUDE.md" ]; then
            echo "✓ CLAUDE.md is a symlink"
        else
            echo "✗ CLAUDE.md is not a symlink"
            exit 1
        fi
    '

print_pass "Coder existing ~/.claude test passed"

echo ""
print_pass "All tests passed!"
