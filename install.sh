#!/bin/bash
set -e

# Dotfiles installer script
# Usage: curl -sSL fx.github.io/dotfiles/install.sh | sh -s -- [profile]

PROFILE="${DOTFILES_PROFILE:-${1:-coder}}"
DOTFILES_REPO="fx/dotfiles"
MISE_INSTALL_URL="https://mise.jdx.dev/install.sh"

# Set Git to automatically accept new SSH keys while preserving existing GIT_SSH_COMMAND
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o StrictHostKeyChecking=accept-new"

# Test git SSH access by attempting to ls-remote
if git ls-remote "git@github.com:${DOTFILES_REPO}.git" >/dev/null 2>&1; then
    DOTFILES_URL="git@github.com:${DOTFILES_REPO}.git"
    echo "Using SSH for dotfiles repository"
else
    DOTFILES_URL="https://github.com/${DOTFILES_REPO}.git"
    echo "Using HTTPS for dotfiles repository"
fi

echo "Installing dotfiles with profile: $PROFILE"

# Check if mise is installed
if command -v mise >/dev/null 2>&1; then
    echo "mise is already installed"
else
    echo "Installing mise..."
    curl -sSL "$MISE_INSTALL_URL" | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Activate mise
eval "$(mise activate bash)"

# Install chezmoi via mise
echo "Installing chezmoi..."
mise use -g chezmoi@latest

# Initialize dotfiles with selected profile
echo "Initializing dotfiles..."
mise exec -- chezmoi init --promptString profile="$PROFILE" "$DOTFILES_URL"

# Apply the dotfiles
echo "Applying dotfiles..."
mise exec -- chezmoi apply

echo "Dotfiles installation complete!"