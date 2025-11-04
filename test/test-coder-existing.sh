#!/bin/bash
# Test Coder environment with existing ~/.claude
set -e

# Create existing ~/.claude with user content
mkdir -p "$HOME/.claude"
echo "user_settings" > "$HOME/.claude/settings.json"
echo "user_custom" > "$HOME/.claude/custom.txt"

# Run setup
/test/setup-dotfiles.sh

# Verify user files preserved
if [ ! -f "$HOME/.claude/custom.txt" ]; then
    echo "✗ User custom.txt not preserved"
    exit 1
fi

if [ ! -d "$HOME/.claude" ]; then
    echo "✗ ~/.claude directory missing"
    exit 1
fi

echo "✓ User files preserved"
