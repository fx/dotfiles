# Dotfiles Principles

**⚠️ WARNING: This is a PUBLIC repository! Never commit personal information, credentials, API keys, or proprietary content to this repository.**

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
