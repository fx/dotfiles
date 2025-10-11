#!/bin/bash
set -e

# Dotfiles installer script
# Usage: curl -sSL fx.github.io/dotfiles/install.sh | sh -s -- [profile]

PROFILE="${DOTFILES_PROFILE:-${1:-default}}"
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

# Purge cached chezmoi directory if it exists
if [ -d "$HOME/.local/share/chezmoi" ]; then
    print_info "Removing cached chezmoi directory..."
    rm -rf "$HOME/.local/share/chezmoi"
fi

# Test git SSH access by attempting to ls-remote
print_step "Checking Git access..."
if git ls-remote "git@github.com:${DOTFILES_REPO}.git" >/dev/null 2>&1; then
    DOTFILES_URL="git@github.com:${DOTFILES_REPO}.git"
    print_success "Using SSH for dotfiles repository"
else
    DOTFILES_URL="https://github.com/${DOTFILES_REPO}.git"
    print_warning "Using HTTPS for dotfiles repository"
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

# Initialize dotfiles with selected profile
print_step "Initializing dotfiles..."
run_or_fail "Failed to initialize dotfiles" mise exec -- chezmoi init --promptString profile="$PROFILE" "$DOTFILES_URL"
print_success "Dotfiles initialized"

# Apply the dotfiles (this automatically runs .chezmoiscripts)
print_step "Applying dotfiles..."
run_or_fail "Failed to apply dotfiles" mise exec -- chezmoi apply
print_success "Dotfiles applied"

echo ""
echo -e "${GREEN}${BOLD}✨ Dotfiles installation complete!${RESET}"
echo ""