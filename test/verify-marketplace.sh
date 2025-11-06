#!/bin/bash
# Verify marketplace configuration and npm packages
set -e

# Ensure mise is activated if available
if command -v mise >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    eval "$(mise activate bash 2>/dev/null)" || true
fi

if [ ! -f "$HOME/.claude/settings.json" ]; then
    echo "✗ settings.json not created"
    exit 1
fi

if ! grep -q "fx-cc" "$HOME/.claude/settings.json"; then
    echo "✗ fx/cc marketplace not configured"
    exit 1
fi

if ! grep -q "git@github.com:fx/cc.git" "$HOME/.claude/settings.json"; then
    echo "✗ Marketplace not using git SSH source"
    exit 1
fi

echo "✓ Claude marketplace configured correctly"

# Verify npm package installation
# Helper function to run npm via mise
run_npm() {
    if command -v mise >/dev/null 2>&1; then
        mise exec -- npm "$@"
    else
        npm "$@"
    fi
}

# Check if npm is available
if command -v mise >/dev/null 2>&1; then
    if ! mise exec -- npm --version >/dev/null 2>&1; then
        echo "⚠️  npm not available, skipping package verification"
        exit 0
    fi
elif ! command -v npm >/dev/null 2>&1; then
    echo "⚠️  npm not available, skipping package verification"
    exit 0
fi

# Parse packages.yaml and verify each npm global package
if command -v yq >/dev/null 2>&1 && [ -f "$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml" ]; then
    # Use yq to parse the YAML file
    npm_packages=$(yq eval '.npm.global[]' "$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml" 2>/dev/null || echo "")
    if [ -n "$npm_packages" ]; then
        while IFS= read -r package; do
            if [ -n "$package" ]; then
                # npm list can exit non-zero due to warnings, so check the output instead
                if ! run_npm list -g "$package" 2>&1 | grep -q "$package@"; then
                    echo "✗ npm package $package not installed"
                    exit 1
                fi
                echo "✓ npm package $package installed correctly"
            fi
        done <<< "$npm_packages"
    fi
else
    # Fallback: Check known packages if yq is not available
    if ! run_npm list -g @anthropic-ai/claude-code 2>&1 | grep -q "@anthropic-ai/claude-code@"; then
        echo "✗ @anthropic-ai/claude-code not installed"
        exit 1
    fi
    echo "✓ @anthropic-ai/claude-code installed correctly"
fi
