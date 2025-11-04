#!/bin/bash
# Verify marketplace configuration
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
