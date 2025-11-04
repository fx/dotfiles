#!/bin/bash
# Common setup script for all test scenarios
set -e

# Install mise and chezmoi
curl -sSL https://mise.jdx.dev/install.sh | sh >/dev/null 2>&1
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
mise use -g chezmoi@latest >/dev/null 2>&1

# Configure git for Docker environment
git config --global --add safe.directory /workspace
git config --global --add safe.directory "*"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"

# Apply dotfiles from local repository
mise exec -- chezmoi init --promptString profile=default /workspace 2>&1 | grep -v "git config" || true
mise exec -- chezmoi apply 2>&1 | grep -v "git config" || true
