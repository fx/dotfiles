# Coder Command

Implement a GitHub issue by fetching it via gh CLI, analyzing requirements, and creating a complete implementation with PR. If no issue is provided, automatically find the next logical issue to work on.

## Usage
```
/coder [<github-issue-url>]
```

## Key Requirements
- **ALWAYS START**: Create a feature branch before any work begins
- **ALWAYS END**: Create a pull request after implementation is complete
- Never work directly on main branch
- Creating a PR is mandatory, not optional
- **WHEN NO ISSUE URL PROVIDED**: You MUST check GitHub Projects FIRST before looking at individual issues

## Instructions

### With Issue URL
Given a GitHub issue URL (e.g., https://github.com/owner/repo/issues/123), you must:

1. **Create feature branch FIRST** - Always start by creating an appropriate branch:
   ```bash
   git checkout main && git pull origin main
   git checkout -b <type>/<issue-number>-<brief-description>
   ```

2. **Update issue status to In Progress** - If issue is linked to a project:
   ```bash
   # Find the issue in project and update status to "In Progress"
   gh project item-edit --id <item-id> --field-id <status-field-id> --project-id <project-id> --single-select-option-id <in-progress-option-id>
   ```

3. **Extract and fetch the issue** - Parse the URL to get owner, repo, and issue number, then fetch using:
   ```bash
   gh issue view <issue-number> --repo <owner>/<repo>
   ```

4. **Analyze requirements** - Understand the ask and create a comprehensive todo list using TodoWrite tool

5. **Implement incrementally** - Work on smaller tasks, making atomic commits at natural checkpoints:
   - Each commit represents a single logical change
   - Use semantic commit messages (max 72 chars)
   - Run tests/linting before commits

6. **Create pull request ALWAYS** - After ALL implementation is complete, you MUST create a PR:
   ```bash
   gh pr create --repo <owner>/<repo> --title "<type>: <subject>" --body "Closes #<issue-number>

   ## Summary
   - What was implemented

   ## Testing
   - How it was tested"
   ```

   **IMPORTANT**: Creating a pull request is NOT optional - it must be the final step of every implementation.

7. **Monitor PR checks** - After creating the PR, you MUST observe and ensure all checks pass:
   ```bash
   # View PR status and checks
   gh pr view <pr-number> --repo <owner>/<repo>

   # Watch checks for up to 5 minutes (in 60 second increments)
   gh pr checks <pr-number> --repo <owner>/<repo> --watch --interval 60
   ```

   **IMPORTANT**: Use `--watch` with a timeout of 60000ms (60 seconds) and run it up to 5 times if needed:
   - First attempt: `gh pr checks <pr-number> --repo <owner>/<repo> --watch` with 60 second timeout
   - If still pending, wait a moment and try again (up to 5 total attempts)
   - This prevents hanging indefinitely while still giving checks time to complete

   If any checks fail:
   - Analyze the failure output: `gh pr checks <pr-number> --repo <owner>/<repo> --verbose`
   - Fix the issues locally
   - Commit and push the fixes
   - Re-run failed checks if needed: `gh pr checks <pr-number> --repo <owner>/<repo> --rerun-failed`
   - Continue monitoring until all checks pass

8. **Update issue status to Done** - After PR is merged:
   ```bash
   # Update issue status in project to "Done"
   gh project item-edit --id <item-id> --field-id <status-field-id> --project-id <project-id> --single-select-option-id <done-option-id>
   ```

### Without Issue URL (Default Behavior)
When no issue URL is provided, you must:

1. **MANDATORY: Check project boards FIRST** - You MUST check for GitHub Projects before doing anything else:
   ```bash
   # Step 1a: List ALL projects for the repository owner
   gh project list --owner <owner>

   # Step 1b: For EACH project found, check for issues in "Todo" status
   gh project item-list <project-number> --owner <owner> --format json | jq '.items[] | select(.status == "Todo")'
   ```

   **CRITICAL**:
   - You MUST check GitHub Projects BEFORE looking at individual issues
   - Issues in "Todo" status on project boards have absolute priority
   - If a project exists, work from the project board, NOT from the issues list
   - Only proceed to step 2 if NO projects exist or NO "Todo" items are found

2. **Analyze recent work** - ONLY if no project "Todo" items found, fetch the most recently merged pull requests:
   ```bash
   gh pr list --repo <owner>/<repo> --state merged --limit 5 --json number,title,body,mergedAt --jq 'sort_by(.mergedAt) | reverse'
   ```

3. **Understand project context** - Review the recent PRs to understand:
   - What features/areas were recently worked on
   - Current project focus and patterns
   - Dependencies or related work

4. **Find next logical issue** - ONLY proceed here if step 1 found no project "Todo" items:
   ```bash
   # List open issues assigned to you
   gh issue list --repo <owner>/<repo> --assignee @me --state open

   # If none assigned, look for unassigned issues with relevant labels
   gh issue list --repo <owner>/<repo> --state open --json number,title,labels,body
   ```

5. **Select appropriate issue** - Selection priority order:
   - **ABSOLUTE PRIORITY**: Issues in "Todo" status on project boards (from step 1)
   - **SECONDARY**: Issues that logically follow recent work
   - **TERTIARY**: Issues in the same feature area or component
   - Priority labels (high, medium, low)
   - Issues without blockers or dependencies
   - If project exists but no "Todo" items, select any issue/epic from the project to progress

   **REMINDER**: You should have already checked projects in step 1. If you skipped it, go back!

6. **Update issue status** - When starting work:
   ```bash
   # Update issue status in project to "In Progress"
   gh project item-edit --id <item-id> --field-id <status-field-id> --project-id <project-id> --single-select-option-id <in-progress-option-id>
   ```

7. **Proceed with implementation** - Once selected, follow these steps:
   - **FIRST**: Create feature branch (as in step 1 of "With Issue URL")
   - Update issue status to "In Progress" on project board
   - Continue with steps 3-4 from "With Issue URL" workflow
   - **THEN**: Always create a pull request (step 5 of "With Issue URL")
   - **FINAL**: Monitor PR checks (step 6 of "With Issue URL")
   - After PR is merged, update issue status to "Done" on project board

## Requirements
- If issue URL provided, use it; otherwise follow default behavior
- Must use gh CLI for all GitHub operations
- Never work on main branch
- Follow all conventions in CLAUDE.md
- When selecting issues automatically, prefer continuity with recent work
