## Git Commits

- Individual commits within a branch that becomes a pull request must be atomic and self-contained.
- Each commit should represent a single logical change to the codebase. This means that if you are making multiple changes, you should break them down into separate commits, each with a clear and descriptive commit message.
- If you encounter "Error: Host key verification failed." error, append `-o StrictHostKeyChecking=accept-new` to GIT_SSH_COMMAND (make sure you use the existing command, NOT simply `ssh`) simply by re-exporting the existing value (e.g. `GIT_SSH_COMMAND="$GIT_SSH_COMMAND -o StrictHostKeyChecking=accept-new")

### Commit message format

- COMMIT MESSAGES MUST be a single line with no line breaks, no longer than 72 characters.
- Use Semantic Conventional Commit Messages (https://www.conventionalcommits.org/en/v1.0.0/)
- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Fix bug" not "Fixed bug")

### Git branch name format

- Use Semantic Conventional Branch naming (https://conventional-branch.github.io/)

## Pull requests

- Pull request titles must follow the same rules as commit messages!
- If the pull requests fixes an issue or ticket, that must be mentioned in its title and description.
- You must use the `gh` CLI app to communicate with github and create pull requests. If it asks you to login, pause and ask the user to authenticate.

## Processes

### Branch, feature, pull request processes

When asked to begin a new branch, feature or pull request, you must follow these steps:

1. Create a new branch, based on `main`, following our branch naming format
2. Analyze the request to understand what exactly you are being asked to implement, then formulate a comprehensive plan
3. Implement the request, or fix the issue and commit your changes when they represent a logical unit of work

### Bug fixing

As a first step to any bug fix there MUST BE a test that fails that confirms the issue. If no all tests pass, you must create a test that tests the specific issue and confirm that it fails before attempting to fix the issue.

## Repository Analysis

### GitIngest Command

When asked to analyze a **PUBLIC** GitHub repository, use the `/gitingest` command to get a comprehensive summary of the repository structure and contents. This command provides:

- Repository tree structure
- File contents digest
- Overall repository summary

**Usage**: `/gitingest <github-url>`

**Example**: `/gitingest https://github.com/user/repo`

**Important Notes**:
- ONLY use this for PUBLIC repositories on GitHub
- The command uses the gitingest CLI tool which may need to be installed on first use
- This provides a quick way to understand repository structure without manually exploring files
- The output includes the repository tree and a digest of important files
