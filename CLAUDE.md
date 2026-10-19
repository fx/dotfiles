# Dotfiles Principles

## ⚠️ THIS IS A PUBLIC REPOSITORY

Everything written here is world-readable. This applies to **every** file —
`docs/`, scripts, comments, commit messages — not just config with secrets in it.

### Never write these into the repo

- Credentials, API keys, tokens, passwords
- Internal/private hostnames and domains (anything not resolvable on the public
  internet, and any personal domain)
- Private IP addresses and MAC addresses (`10.x`, `172.16-31.x`, `192.168.x`,
  `100.64.x` / Tailscale, link-local)
- SSID names, Wi-Fi BSSIDs, router or AP identifiers
- Internal service, machine, workspace, or cluster names; internal URLs;
  employer/client names and proprietary details
- Real usernames, emails, phone numbers, physical addresses

### The trap: debugging output

**The most common way this leaks is pasting real output from a live debugging
session into `docs/`.** Terminal output, error messages, `ip`/`nmcli`/`curl`
transcripts, and log excerpts are full of real hostnames, IPs, and MACs. They are
useful to document — but you MUST rewrite them with placeholders first. Never
copy a real transcript verbatim.

Use generic placeholders that keep the example legible:

| Instead of | Write |
|---|---|
| a real internal hostname | `internal.example`, `service.example` |
| a real private IP | `<lan-ip>`, `10.0.0.5`, `192.0.2.10` (TEST-NET) |
| a real MAC | `aa:bb:cc:dd:ee:ff` |
| a real SSID | `<ssid>`, `MyNetwork` |
| a real internal tool/host name | `some-cli`, `<host>` |

The documented *cause, fix, and verification* are what matter. The specific
address something failed at never is.

### Before writing or committing

Grep your own changes and confirm they come back clean:

```bash
git diff; git status --short          # review untracked files too
grep -rInE '192\.168\.|10\.[0-9]+\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.|([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' <changed-files>
```

Then re-read each changed file and ask: *would a stranger learn anything about
this person's network, employer, or accounts from it?* If yes, replace it with a
placeholder. When unsure whether something is sensitive, treat it as sensitive.

## Desktop Profile

**When working on desktop-related issues (Hyprland, gaming, Proton/Wine, NVIDIA, Stream Deck), ALWAYS read `docs/desktop.md` first.** It contains critical troubleshooting info and known fixes for common issues. Game-specific recipes live under `docs/games/` (e.g., `docs/games/star-citizen.md`).

## Running Dotfiles

**CRITICAL: NEVER run `chezmoi` directly. ALWAYS use `./install.sh` to apply changes.**

```bash
# Correct - always use this:
./install.sh

# Opt in to a full `pacman -Syu` as well (off by default):
./install.sh --update

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

## Claude Code Settings

`.chezmoidata/claude.yaml` holds the Claude Code settings the dotfiles enforce.
`.chezmoiscripts/run_onchange_after_update-claude-settings.sh.tmpl` jq-merges them
into `~/.claude/settings.json` (or creates it), preserving every other user setting.

The merge only adds and overwrites keys. Removing a key from `claude.yaml` does
not remove it from an existing `settings.json` — delete it there by hand.

## Agent Skills

`.chezmoiscripts/run_after_update-agent-skills.sh.tmpl` installs
[fx/skills](https://github.com/fx/skills) for Claude Code, Codex and pi with the
[`skills`](https://github.com/vercel-labs/skills) CLI on every apply. The CLI places
everything: content in `~/.agents/skills` (read directly by Codex and pi), one
symlink per skill in `~/.claude/skills`. It never prunes — remove a skill dropped
from fx/skills with `npx skills@1.7.2 remove -g <name>`.

In Coder, `~/.agents` and `$DOTFILES_SHARED_HOME/.agents` both link to
`/shared/agents`, so the store survives rebuilds and the CLI's relative links
(`../../.agents/skills/<name>`) resolve from either home.

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
