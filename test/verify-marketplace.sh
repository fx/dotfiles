#!/bin/bash
# Verify marketplace configuration and Claude Code installation
set -e

if [ ! -f "$HOME/.claude/settings.json" ]; then
    echo "✗ settings.json not created"
    exit 1
fi

if ! jq -e '.extraKnownMarketplaces["anthropic-agent-skills"].source.repo == "anthropics/skills"' \
        "$HOME/.claude/settings.json" >/dev/null; then
    echo "✗ Claude marketplace not configured"
    exit 1
fi

echo "✓ Claude marketplace configured correctly"

# fx/skills: content in ~/.agents/skills, a resolving link per skill in ~/.claude/skills.
if [ ! -e "$HOME/.claude/skills/dev/SKILL.md" ]; then
    echo "✗ fx/skills not installed for Claude Code"
    exit 1
fi
echo "✓ fx/skills installed"

# Verify Claude Code is installed. mise installs it as a managed tool with a shim
# under ~/.local/share/mise/shims (NOT ~/.local/bin), and mise isn't necessarily on
# PATH in this verification shell, so check both locations directly.
if [ -x "$HOME/.local/bin/claude" ] || [ -x "$HOME/.local/share/mise/shims/claude" ]; then
    echo "✓ Claude Code installed"
else
    echo "✗ Claude Code not installed"
    exit 1
fi
