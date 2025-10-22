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