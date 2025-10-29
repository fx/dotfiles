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

1. Store your GitHub token once in `/shared/.config/gh/hosts.yml`
2. The dotfiles setup script creates a symlink: `~/.config/gh` → `/shared/.config/gh`
3. All workspaces automatically use the same authentication
4. Token persists across workspace rebuilds since `/shared` is persistent storage

### Setup Instructions

1. In any coder workspace, copy your existing token to the shared location:
   ```bash
   mkdir -p /shared/.config/gh
   cp ~/.config/gh/hosts.yml /shared/.config/gh/hosts.yml
   chmod 600 /shared/.config/gh/hosts.yml
   ```

2. Or create `/shared/.config/gh/hosts.yml` manually:
   ```yaml
   github.com:
       user: YOUR_USERNAME
       oauth_token: YOUR_TOKEN_HERE
       git_protocol: https
   ```

3. The dotfiles `run_onchange_after_setup-shared-symlinks.sh.tmpl` script will automatically create the symlink in all workspaces

### Security Notes

- The `/shared` directory is persistent across workspace rebuilds
- Access is limited to your Kubernetes namespace
- Token file should have `600` permissions
- Never commit GitHub tokens to any repository

## Claude Configuration Synchronization

The Claude configuration in `shared/claude/` is synchronized from the system Claude configuration. This ensures consistent AI assistant behavior across the codebase.

### Synchronization Rules

1. **One-way sync**: Files are only copied FROM the system configuration TO this repository, never the reverse
2. **Existing files only**: Only files that already exist in `shared/claude/` are synchronized
3. **Referenced files included**: If synchronized files reference other files (e.g., agents referenced in commands), those are brought along
4. **⚠️ NO SENSITIVE OR PROPRIETARY DATA**: The sync process MUST exclude:
   - Session data, cache files, and temporary files
   - Project-specific conversation histories (`projects/` directory)
   - Shell snapshots and statsig data
   - Todo lists and other runtime data
   - Personal information, credentials, API keys, tokens, or passwords
   - Company/employer-specific content, product names, or proprietary terminology
   - Work-related agents, commands, or configuration files
   - Internal URLs, endpoints, or infrastructure details
   - Any content that references specific companies, products, or clients

### What Gets Synchronized

The following are synchronized from system Claude config to this repository:
- `CLAUDE.md` - Core configuration and conventions
- `settings.json` - Editor settings (with personal data removed)
- `commands/` - Generic command workflows
- `agents/` - Generic agent definitions

Only sync files that are generic and contain no proprietary content. Exclude anything employer/client/project-specific.

### Manual Sync Process

To manually sync Claude configuration:
1. Identify changed files in the source configuration
2. **⚠️ SECURITY CHECK**: Review files for ANY sensitive or proprietary content
3. Copy ONLY safe, generic files that exist in `shared/claude/`
4. Check for any newly referenced files and copy those too (if safe)
5. **⚠️ FINAL VERIFICATION**: Review all changes with `git diff` to ensure no sensitive data is included
6. Commit the changes with a clear message describing what was synced

**NEVER sync**:
- Files containing company/product names, proprietary terminology
- Work-specific agents, commands, or workflows
- Personal information, credentials, or internal infrastructure details

## Ultimate Goal

Host a shell script on GitHub Pages (e.g., fx.github.io/dotfiles/install.sh) that can be run via:
```bash
curl -sSL fx.github.io/dotfiles/install.sh | sh
```

This script should work on any Linux distribution and handle profile selection.