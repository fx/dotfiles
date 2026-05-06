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

# Verify Claude Code is installed (mise installs to ~/.local/bin)
CLAUDE_BIN="$HOME/.local/bin/claude"
if [ -x "$CLAUDE_BIN" ]; then
    echo "✓ Claude Code installed"
else
    echo "✗ Claude Code not installed"
    exit 1
fi
