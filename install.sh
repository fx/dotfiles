#!/bin/bash
set -e

# Dotfiles installer script
# Usage: curl -sSL fx.github.io/dotfiles/install.sh | sh -s -- [profile]
#
# Environment variables:
#   DEBUG=1       - Show detailed error output when git fails
#   FORCE_SSH=1   - Fail entirely if SSH doesn't work (no HTTPS fallback)

# Auto-detect desktop profile if not specified
if [ -n "$1" ]; then
    PROFILE="$1"
elif [ -n "$DOTFILES_PROFILE" ]; then
    PROFILE="$DOTFILES_PROFILE"
elif command -v hyprctl >/dev/null 2>&1; then
    PROFILE="desktop"
else
    PROFILE="default"
fi
DOTFILES_REPO="fx/dotfiles"
MISE_INSTALL_URL="https://mise.jdx.dev/install.sh"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Helper functions for colored output
print_step() { echo -e "${BLUE}${BOLD}→${RESET} ${CYAN}$1${RESET}"; }
print_success() { echo -e "${GREEN}${BOLD}✓${RESET} ${GREEN}$1${RESET}"; }
print_warning() { echo -e "${YELLOW}${BOLD}⚠${RESET} ${YELLOW}$1${RESET}"; }
print_error() { echo -e "${RED}${BOLD}✗${RESET} ${RED}$1${RESET}"; }
print_info() { echo -e "${MAGENTA}${BOLD}ℹ${RESET} ${MAGENTA}$1${RESET}"; }

# Run command with error handling
run_or_fail() {
    local msg="$1"
    shift
    if ! "$@" 2>&1 | tee -a /tmp/install.log; then
        print_error "$msg"
        echo ""
        echo "Error details:"
        tail -20 /tmp/install.log
        exit 1
    fi
}

# Set Git to automatically accept new SSH keys while preserving existing GIT_SSH_COMMAND
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o StrictHostKeyChecking=accept-new"

# Purge cached chezmoi directory and state if they exist
if [ -d "$HOME/.local/share/chezmoi" ]; then
    print_info "Removing cached chezmoi directory..."
    rm -rf "$HOME/.local/share/chezmoi"
fi
if [ -f "$HOME/.config/chezmoi/chezmoistate.boltdb" ]; then
    print_info "Removing chezmoi state database..."
    rm -f "$HOME/.config/chezmoi/chezmoistate.boltdb"
fi

# Detect if we're running from within the dotfiles repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_MODE=false
if [ -f "$SCRIPT_DIR/.chezmoiignore" ] && [ -d "$SCRIPT_DIR/.chezmoiscripts" ]; then
    LOCAL_MODE=true
    print_success "Using local dotfiles repository at $SCRIPT_DIR"
else
    # Test git SSH access by attempting to ls-remote (5 second timeout)
    print_step "Checking Git access..."
    GIT_SSH_ERROR=$(mktemp)
    if timeout 5 git ls-remote "git@github.com:${DOTFILES_REPO}.git" >/dev/null 2>"$GIT_SSH_ERROR"; then
        DOTFILES_URL="git@github.com:${DOTFILES_REPO}.git"
        print_success "Using SSH for dotfiles repository"
        rm -f "$GIT_SSH_ERROR"
    else
        SSH_EXIT_CODE=$?
        if [ "${DEBUG:-0}" = "1" ]; then
            print_error "SSH git access failed (exit code: $SSH_EXIT_CODE)"
            echo "Error output:"
            cat "$GIT_SSH_ERROR"
            echo ""
        fi
        rm -f "$GIT_SSH_ERROR"

        if [ "${FORCE_SSH:-0}" = "1" ]; then
            print_error "SSH access required (FORCE_SSH=1) but SSH failed"
            print_info "Run with DEBUG=1 for more details"
            exit 1
        fi

        DOTFILES_URL="https://github.com/${DOTFILES_REPO}.git"
        print_warning "Using HTTPS for dotfiles repository (SSH failed)"
    fi
fi

echo ""
echo -e "${BOLD}🚀 Installing dotfiles${RESET}"
echo -e "${BOLD}   Profile: ${CYAN}$PROFILE${RESET}"
echo ""

# Check if mise is installed
if command -v mise >/dev/null 2>&1; then
    print_success "mise is already installed"
else
    print_step "Installing mise..."
    run_or_fail "Failed to install mise" sh -c "curl -sSL '$MISE_INSTALL_URL' | sh"
    export PATH="$HOME/.local/bin:$PATH"
    print_success "mise installed"
fi

# Activate mise
eval "$(mise activate bash)" 2>>/tmp/install.log || run_or_fail "Failed to activate mise" false

# Install chezmoi via mise
print_step "Installing chezmoi..."
run_or_fail "Failed to install chezmoi" mise use -g chezmoi@latest
print_success "chezmoi installed"

# Initialize and apply dotfiles
if [ "$LOCAL_MODE" = true ]; then
    # Local dev mode: use --source to apply directly from working tree
    print_step "Configuring for local development..."

    # Generate chezmoi config with profile settings
    CHEZMOI_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
    mkdir -p "$(dirname "$CHEZMOI_CONFIG")"

    IS_DESKTOP=false
    [ "$PROFILE" = "desktop" ] && IS_DESKTOP=true

    cat > "$CHEZMOI_CONFIG" << EOF
[data]
    profile = "$PROFILE"
    include_defaults = true
    is_desktop = $IS_DESKTOP

[diff]
    pager = "less"
EOF
    print_success "Configuration ready"

    # Apply directly from local source
    print_step "Applying dotfiles..."
    run_or_fail "Failed to apply dotfiles" mise exec -- chezmoi apply --source="$SCRIPT_DIR" --force
else
    # Remote mode: use chezmoi init + apply
    print_step "Initializing dotfiles..."
    INIT_OUTPUT=$(mktemp)
    if mise exec -- chezmoi init --promptString profile="$PROFILE" "$DOTFILES_URL" >"$INIT_OUTPUT" 2>&1; then
        grep -v "Cloning into" "$INIT_OUTPUT" | grep -v "^done\.$" || true
        rm -f "$INIT_OUTPUT"
    else
        grep -v "Cloning into" "$INIT_OUTPUT" | grep -v "^done\.$" || true
        rm -f "$INIT_OUTPUT"
        print_error "Failed to initialize dotfiles"
        exit 1
    fi
    print_success "Dotfiles initialized"

    print_step "Applying dotfiles..."
    run_or_fail "Failed to apply dotfiles" mise exec -- chezmoi apply --force
fi
print_success "Dotfiles applied"

echo ""
echo -e "${GREEN}${BOLD}✨ Dotfiles installation complete!${RESET}"
echo ""