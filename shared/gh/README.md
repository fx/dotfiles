# GitHub CLI Configuration

This directory contains GitHub CLI (`gh`) configuration that is automatically synced to `/shared/.config/gh` and symlinked to `~/.config/gh` in all workspaces.

## Setup Instructions

### First Time Setup

1. The dotfiles setup will seed this directory to `/shared/.config/gh` if it doesn't exist
2. Update the `hosts.yml` file with your actual GitHub token:

```bash
# Edit the hosts.yml file in /shared/.config/gh
nano /shared/.config/gh/hosts.yml
```

3. Replace `YOUR_TOKEN_HERE` with your actual GitHub Personal Access Token
4. Ensure proper permissions:

```bash
chmod 600 /shared/.config/gh/hosts.yml
```

### Getting Your GitHub Token

Visit https://github.com/settings/tokens/new and create a Personal Access Token with these scopes:
- `repo` (Full control of private repositories)
- `read:org` (Read org and team membership)
- `workflow` (Update GitHub Action workflows)

## How It Works

1. The dotfiles script seeds `/shared/.config/gh` from `dotfiles/shared/gh/` (only if it doesn't exist)
2. A symlink is created: `~/.config/gh` → `/shared/.config/gh`
3. All workspaces use the same authentication automatically
4. Token persists across workspace rebuilds

## Files

- `hosts.yml` - GitHub authentication configuration (contains your token)
- `config.yml` - GitHub CLI preferences

## Security Notes

- The `/shared` directory persists across workspace rebuilds
- Access is limited to your Kubernetes namespace
- Token file should have `600` permissions
- Never commit GitHub tokens to any repository
- The template `hosts.yml` contains a placeholder that MUST be replaced with your actual token
