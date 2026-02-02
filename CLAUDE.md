# Dotfiles Principles

**⚠️ WARNING: This is a PUBLIC repository! Never commit personal information, credentials, API keys, or proprietary content to this repository.**

## Desktop Profile

**When working on desktop-related issues (Hyprland, gaming, Proton/Wine, NVIDIA, Stream Deck), ALWAYS read `docs/DESKTOP.md` first.** It contains critical troubleshooting info and known fixes for common issues.

## Running Dotfiles

**CRITICAL: NEVER run `chezmoi` directly. ALWAYS use `./install.sh` to apply changes.**

```bash
# Correct - always use this:
./install.sh

# WRONG - never do this:
chezmoi apply  # NO!
```

The install script handles chezmoi installation, profile detection, and proper initialization. Running chezmoi directly will fail or produce incorrect results.

## Git Commits

**NEVER automatically commit changes to this repository.** Always wait for explicit user approval before committing. Present the changes and ask if they should be committed.

## Installation Hierarchy

1. **chezmoi first**: Always use chezmoi for installations and configuration management
2. **mise second**: Use mise only when chezmoi is unsuitable (e.g., installing chezmoi itself)
3. **Direct installation last**: Use direct installations (apt, etc.) only when both chezmoi and mise are unsuitable

## Profile Management

- Dotfiles use chezmoi's template system with a `profile` variable
- Profiles are defined in `profiles.yaml` for documentation
- Installation uses `--promptString profile=NAME` to set the profile
- Files are conditionally installed based on `{{ if eq .profile "name" }}` templates
- Shared configurations (like claude) are symlinked conditionally based on profile

## GitHub CLI Shared Authentication

GitHub CLI (`gh`) authentication is managed via shared configuration stored in `/shared/.config/gh/` on coder workspaces. This eliminates the need to run `gh auth login` in every workspace.

### How It Works

1. On first run, dotfiles seeds `/shared/.config/gh/` from `dotfiles/shared/gh/` (template files with placeholders)
2. User updates `/shared/.config/gh/hosts.yml` with their actual GitHub token
3. The dotfiles setup script creates a symlink: `~/.config/gh` → `/shared/.config/gh`
4. All workspaces automatically use the same authentication
5. Token persists across workspace rebuilds since `/shared` is persistent storage

### Setup Instructions

1. **First workspace**: The dotfiles script will automatically seed `/shared/.config/gh/` with template files
2. **Update your token**: Edit the seeded template with your actual GitHub token:
   ```bash
   nano /shared/.config/gh/hosts.yml
   # Replace YOUR_TOKEN_HERE with your actual token
   ```
3. **Set permissions**:
   ```bash
   chmod 600 /shared/.config/gh/hosts.yml
   ```
4. **Done**: All current and future workspaces will automatically use this token

### Getting Your GitHub Token

Visit https://github.com/settings/tokens/new and create a Personal Access Token with these scopes:
- `repo` (Full control of private repositories)
- `read:org` (Read org and team membership)
- `workflow` (Update GitHub Action workflows)

### Files in `shared/gh/`

- `hosts.yml` - Template for GitHub authentication (contains placeholders)
- `config.yml` - GitHub CLI preferences
- `README.md` - Instructions for setup

### Security Notes

- The `/shared` directory is persistent across workspace rebuilds
- Access is limited to your Kubernetes namespace
- Token file should have `600` permissions (set automatically)
- Never commit GitHub tokens to any repository
- The template files contain placeholders that MUST be replaced with your actual credentials

## Claude Code Marketplace

Claude Code plugins, skills, and agents are distributed via the `fx/cc` marketplace repository. The dotfiles automatically configure this marketplace for development.

### How It Works

1. **Automatic Configuration**: Dotfiles configure `fx/cc` marketplace via `~/.claude/settings.json`:
   - Marketplace configuration is stored in `.chezmoidata/claude.yaml`
   - A `modify_` script merges this config into existing settings.json (or creates it if missing)
   - User settings are preserved; only marketplace config and required settings are enforced
   - Uses chezmoi's template system with `jq` for JSON merging

   Example configuration:
   ```json
   {
     "extraKnownMarketplaces": {
       "fx-cc": {
         "source": {
           "source": "git",
           "url": "git@github.com:fx/cc.git"
         }
       }
     }
   }
   ```

2. **Auto-Clone**: When you trust the workspace, Claude Code automatically clones the repository via SSH to:
   - `~/.claude/plugins/marketplaces/fx-cc/`
   - Full git repository with SSH remote
   - Ready for development (commit, push, etc.)

3. **Plugin Discovery**: Use `/plugin marketplace list` to see available plugins

4. **Installation**: Install desired plugins:
   ```bash
   /plugin install fx-dev     # Development agents and commands
   /plugin install fx-test    # Test plugin
   ```

### Available Plugins

Visit [https://cc.fx.gd](https://cc.fx.gd) or check `~/.claude/plugins/marketplaces/fx-cc/` to see available plugins.

### Development Workflow

**Making changes to plugins:**
```bash
# Navigate to the marketplace repository
cd ~/.claude/plugins/marketplaces/fx-cc

# Make changes to plugins
vim plugins/fx-dev/agents/coder.md

# Commit and push
git add .
git commit -m "feat(fx-dev): improve coder agent"
git push
```

**Creating a new plugin:**
```bash
cd ~/.claude/plugins/marketplaces/fx-cc

# Create plugin structure
mkdir -p plugins/my-plugin/{.claude-plugin,agents,skills}
cd plugins/my-plugin

# Create manifest
cat > .claude-plugin/plugin.json <<EOF
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "My custom plugin"
}
EOF

# Add your agents/skills/commands
# ...

# Update marketplace.json
cd ../..
vim .claude-plugin/marketplace.json

# Commit and push
git add .
git commit -m "feat: add my-plugin"
git push
```

**Testing changes:**
- Changes are immediately available to Claude Code
- Reload Claude Code window to pick up changes
- Use `/plugin update fx-cc` to refresh marketplace

### Updates

Claude Code automatically manages marketplace updates. The repository in `~/.claude/plugins/marketplaces/fx-cc/` is a full git repository, so you can:
- Pull updates: `cd ~/.claude/plugins/marketplaces/fx-cc && git pull`
- Switch branches for testing
- Make local changes and push upstream

### Security Notes

- SSH clone requires GitHub SSH key authentication
- Uses existing gh CLI authentication for SSH keys
- Repository is owned by you and fully under your control
- Never commit sensitive data to plugin repositories

## Home Assistant Integration (Desktop Profile)

The OpenDeck Stream Deck configuration includes Home Assistant integration for controlling lights via the second encoder knob.

For OpenDeck profile format details (encoder context format, button layout), see `dot_config/opendeck/README.md`.

### Credentials Storage

**IMPORTANT**: Home Assistant credentials are stored locally and are NOT managed by chezmoi or committed to the repository.

Credentials are stored at: `~/.config/home-assistant/credentials`

This file contains:
```bash
HA_URL="http://your-ha-instance:8123"
HA_TOKEN="your_long_lived_access_token"
HA_LIGHT_ENTITY="light.your_light_entity"
```

### Setup

During `chezmoi apply`, you'll be prompted for Home Assistant credentials if not already configured:

1. **Home Assistant URL**: Your HA instance URL (e.g., `http://192.168.1.100:8123`)
2. **Long-lived access token**: Create one in HA under Profile → Long-Lived Access Tokens
3. **Light entity ID**: The entity you want to control (e.g., `light.office`)

You can skip the prompt (Ctrl+C) and configure later by creating the credentials file manually.

### Stream Deck Controls

- **Encoder 1 (left)**: Volume control - rotate to adjust, press to mute
- **Encoder 2**: Light control - rotate to dim, press to toggle on/off

### Manual Configuration

If you skipped the interactive setup or need to update credentials:

```bash
mkdir -p ~/.config/home-assistant
cat > ~/.config/home-assistant/credentials << 'EOF'
HA_URL="http://your-ha-instance:8123"
HA_TOKEN="your_long_lived_access_token"
HA_LIGHT_ENTITY="light.your_light_entity"
EOF
chmod 600 ~/.config/home-assistant/credentials
```

### Getting a Long-Lived Access Token

1. Open your Home Assistant instance
2. Click your profile (bottom left)
3. Scroll to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Give it a name (e.g., "Stream Deck")
6. Copy the token immediately (it won't be shown again)

### Security Notes

- Credentials file has 600 permissions (owner read/write only)
- The `~/.config/home-assistant/` directory is NOT managed by chezmoi
- Never commit credentials to any repository
- The token grants full API access to your HA instance - keep it secure

## Nerd Font Icons (Desktop Profile)

When adding icons to waybar, scripts, or other desktop tools, **always use Nerd Font icons** (monochrome glyphs) instead of standard Unicode emoji.

### Resources

- **Cheat Sheet**: https://www.nerdfonts.com/cheat-sheet
- **Installed Font**: `ttf-hack-nerd` (in packages.yaml)

### Common Icons

| Purpose | Icon | Codepoint | Name |
|---------|------|-----------|------|
| Volume high | | U+F028 | nf-fa-volume_high |
| Volume low | | U+F027 | nf-fa-volume_low |
| Volume muted | | U+F026 | nf-fa-volume_off |
| Wifi | | U+F1EB | nf-fa-wifi |
| Ethernet | | U+F796 | nf-fa-ethernet |
| Warning | | U+F071 | nf-fa-warning |
| Battery full | | U+F240 | nf-fa-battery_full |
| Battery 3/4 | | U+F241 | nf-fa-battery_three_quarters |
| Battery 1/2 | | U+F242 | nf-fa-battery_half |
| Battery 1/4 | | U+F243 | nf-fa-battery_quarter |
| Battery empty | | U+F244 | nf-fa-battery_empty |
| Charging/bolt | | U+F0E7 | nf-fa-bolt |
| Plug | | U+F1E6 | nf-fa-plug |
| Search/magnify | | U+F002 | nf-fa-search |

### Writing Nerd Font Icons in Files

**IMPORTANT**: The Edit/Write tools may strip special Unicode characters. Use `printf` with escaped codepoints via Bash instead:

```bash
# Single icon
printf '\uf028'  # Volume high

# In a file (e.g., JSON config)
printf '        "format-wifi": "%s {essid}",\n' "$(printf '\uf1eb')" >> config.json

# Multiple icons in an array
printf '        "format-icons": ["%s", "%s", "%s"]\n' \
  "$(printf '\uf244')" "$(printf '\uf243')" "$(printf '\uf240')" >> config.json
```

### Verifying Icons

Check that bytes were written correctly:
```bash
grep "format-wifi" config.json | xxd | head -5
# Should see bytes like: ef87ab (UTF-8 for U+F1EB)
```

## Audio Toggle (Desktop Profile)

The `audio-toggle` script switches between two audio outputs (e.g., HDMI speakers and USB headphones). Device names are machine-specific and configured locally.

### Configuration

Create the config file with your audio device names:

```bash
mkdir -p ~/.config/audio-toggle
cat > ~/.config/audio-toggle/config << 'EOF'
AUDIO_SINK_SPEAKERS="alsa_output.pci-xxxx_xx_xx.x.hdmi-stereo-extra3"
AUDIO_SINK_HEADPHONES="alsa_output.usb-Your_Device-00.analog-stereo"

# Optional: For HDMI outputs requiring card profile switching
AUDIO_CARD="alsa_card.pci-xxxx_xx_xx.x"
AUDIO_PROFILE="output:hdmi-stereo-extra3"
EOF
```

### Finding Device Names

```bash
# List available sinks
pactl list sinks short

# For HDMI, find card profiles
pactl list cards | grep -E "(Name:|profile|hdmi)" | head -40
```

### Usage

Run `audio-toggle` directly or bind to a Stream Deck button. It toggles between outputs and prints an emoji (🔊/🎧) indicating the current state.

## Testing

### Testing Workflow

**CRITICAL**: All tests MUST pass locally before committing changes:

1. **Run tests locally first**:
   ```bash
   sudo service docker start  # if needed
   ./test/test-dotfiles.sh
   ```

2. **Only commit if tests pass locally**

3. **CI validates the same tests** - should always pass if local tests passed

### Local Testing

The dotfiles include automated tests that verify both Coder and non-Coder installation scenarios using Docker.

**Prerequisites:**
- Docker installed and running
- If Docker is not running: `sudo service docker start`

**Run tests:**
```bash
./test/test-dotfiles.sh
```

**What it tests:**
1. **Non-Coder Environment**: Verifies dotfiles installation and marketplace configuration
2. **Coder Fresh Install**: Verifies `/shared/` seeding and marketplace configuration
3. **Coder Existing ~/.claude**: Verifies user files are preserved

### CI Testing

Tests run automatically on:
- Push to `main` branch
- Pull requests to `main` branch

The CI workflow (`.github/workflows/test.yml`) uses GitHub Actions and runs the same test script in an Ubuntu environment.

**Note**: CI tests should always pass if local tests passed. If CI fails but local tests pass, there's likely an environment difference that needs investigation.

## Ultimate Goal

Host a shell script on GitHub Pages (e.g., fx.github.io/dotfiles/install.sh) that can be run via:
```bash
curl -sSL fx.github.io/dotfiles/install.sh | sh
```

This script should work on any Linux distribution and handle profile selection.
