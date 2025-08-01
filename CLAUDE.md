# Dotfiles Principles

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

## Claude Configuration Synchronization

The Claude configuration in `shared/claude/` is synchronized from the system Claude configuration. This ensures consistent AI assistant behavior across the codebase.

### Synchronization Rules

1. **One-way sync**: Files are only copied FROM the system configuration TO this repository, never the reverse
2. **Existing files only**: Only files that already exist in `shared/claude/` are synchronized
3. **Referenced files included**: If synchronized files reference other files (e.g., agents referenced in commands), those are brought along
4. **No sensitive data**: The sync process excludes sensitive files like:
   - Session data, cache files, and temporary files
   - Project-specific conversation histories (`projects/` directory)
   - Shell snapshots and statsig data
   - Todo lists and other runtime data

### Files Synchronized

The following files and directories are synchronized:
- `CLAUDE.md` - Main configuration file with git and PR conventions
- `settings.json` - Claude settings
- `commands/` - Custom command definitions (coder.md, gitingest.sh)
- `agents/` - Agent definitions referenced by commands (requirements-analyzer, planner, issue-updater, pr-preparer, pr-check-monitor, coder)

### Manual Sync Process

To manually sync Claude configuration:
1. Identify changed files in the source configuration
2. Copy only matching files that exist in `shared/claude/`
3. Check for any newly referenced files and copy those too
4. Verify no sensitive data is included
5. Commit the changes

## Ultimate Goal

Host a shell script on GitHub Pages (e.g., fx.github.io/dotfiles/install.sh) that can be run via:
```bash
curl -sSL fx.github.io/dotfiles/install.sh | sh
```

This script should work on any Linux distribution and handle profile selection.