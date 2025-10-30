# Dotfiles Testing

This directory contains automated tests for the dotfiles installation system.

## Test Suite

The `test-dotfiles.sh` script validates dotfiles installation in three scenarios:

1. **Non-Coder Environment**: Verifies direct symlinking from dotfiles repository
2. **Coder Fresh Install**: Verifies `/shared/` directory seeding and full directory symlink
3. **Coder Existing ~/.claude**: Verifies selective subdirectory symlinking when `~/.claude` already exists

## Requirements

### Docker Image

The tests use a custom Docker image: `ghcr.io/fx/docker/devcontainer:latest`

This image is built from the [fx/docker](https://github.com/fx/docker) repository and provides a consistent test environment with:
- Base Linux distribution for testing
- Common development tools
- User environment similar to actual workspaces

**Note**: The image is publicly available from GitHub Container Registry. If you need to build it locally or use a different image, modify the `IMAGE` variable in `test-dotfiles.sh`.

### Docker

Docker must be installed and running:

```bash
# Check if Docker is running
docker info

# Start Docker if needed
sudo service docker start
```

## Running Tests

### Local Testing

```bash
# From repository root
./test/test-dotfiles.sh

# Or with sudo if needed
sudo ./test/test-dotfiles.sh
```

### CI Testing

Tests run automatically via GitHub Actions on:
- Push to `main` branch
- Pull requests to `main` branch

See `.github/workflows/test.yml` for CI configuration.

## Test Scenarios Explained

### Test 1: Non-Coder Environment

Simulates installation on a personal machine where `/shared/` directory doesn't exist. Verifies that `~/.claude` becomes a symlink directly to the dotfiles repository.

### Test 2: Coder Fresh Install

Simulates first-time installation in a Coder workspace. Verifies:
- `/shared/home/default/.claude` is seeded from dotfiles
- `~/.claude` is a symlink to `/shared/home/default/.claude`

### Test 3: Coder Existing ~/.claude

Simulates installation when user already has a `~/.claude` directory with custom content. Verifies:
- `~/.claude` remains a real directory (not symlink)
- User files are preserved
- Only subdirectories (`agents`, `commands`, `skills`) and `CLAUDE.md` are symlinked
