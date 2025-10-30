# GitHub Copilot Instructions

## Code Reviews

### Test Suite Conventions

- Do not suggest refactoring test scripts to use `install.sh` when the test intentionally bypasses it to test specific chezmoi behavior (e.g., selective symlinking with pre-existing directories)
- Tests may directly invoke chezmoi commands when they need to control the environment state before installation
