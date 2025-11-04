#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_test() { echo -e "${YELLOW}TEST:${NC} $1"; }
print_pass() { echo -e "${GREEN}✓${NC} $1"; }
print_fail() { echo -e "${RED}✗${NC} $1"; }

# Check Docker
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Try:"
    echo "  sudo service docker start"
    echo "  sudo ./test/test-dotfiles.sh"
    exit 1
fi

IMAGE="ghcr.io/fx/docker/devcontainer:latest"
docker pull "$IMAGE" >/dev/null 2>&1

# Make test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Test 1: Non-Coder Environment
print_test "Non-Coder Environment"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -v "$SCRIPT_DIR:/test" \
    -w /workspace \
    -e CODER="" \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    "$IMAGE" \
    bash -c '/test/setup-dotfiles.sh && /test/verify-marketplace.sh'

print_pass "Non-Coder test passed"

# Test 2: Coder Fresh Install
print_test "Coder Fresh Install"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -v "$SCRIPT_DIR:/test" \
    -w /workspace \
    -e CODER=true \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    --tmpfs /shared:rw,exec \
    "$IMAGE" \
    bash -c '/test/setup-dotfiles.sh && /test/verify-marketplace.sh'

print_pass "Coder fresh install test passed"

# Test 3: Coder with Existing ~/.claude
print_test "Coder with Existing ~/.claude"
docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -v "$SCRIPT_DIR:/test" \
    -w /workspace \
    -e CODER=true \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    --tmpfs /shared:rw,exec \
    "$IMAGE" \
    bash /test/test-coder-existing.sh

print_pass "Coder existing ~/.claude test passed"

echo ""
print_pass "All tests passed!"
