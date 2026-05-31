#!/bin/bash
# Verify marketplace configuration and Claude Code installation
set -e

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

# Verify Claude Code is installed. mise installs it as a managed tool with a shim
# under ~/.local/share/mise/shims (NOT ~/.local/bin), and mise isn't necessarily on
# PATH in this verification shell, so check both locations directly.
if [ -x "$HOME/.local/bin/claude" ] || [ -x "$HOME/.local/share/mise/shims/claude" ]; then
    echo "✓ Claude Code installed"
else
    echo "✗ Claude Code not installed"
    exit 1
fi
