# Coder Command

Orchestrates the complete software development lifecycle for implementing GitHub issues using specialized agents. This command manages requirements analysis, planning, implementation, PR preparation, and monitoring through a coordinated agent workflow.

## Usage
```
/coder [<github-issue-url>]
```

## Overview
The coder command coordinates multiple specialized agents to ensure comprehensive, high-quality implementations:

1. **Requirements Analysis** - Fetch and analyze GitHub issues, extract requirements, gather context
2. **Planning** - Create detailed implementation plans following project conventions
3. **Implementation** - Execute the plan with proper branching, commits, and testing
4. **PR Preparation** - Clean up commits, ensure compliance, create professional PRs
5. **Monitoring** - Watch PR checks and automatically fix failures until all pass

## Workflow

### Phase 1: Requirements & Planning

1. **Requirements Analysis**:
   ```
   Use requirements-analyzer agent to:
   - Fetch GitHub issue (or find next logical issue)
   - Extract all requirements and acceptance criteria
   - Gather context from referenced URLs
   - Compile comprehensive requirements document
   ```

2. **Check for Existing Plan**:
   ```
   Check if issue has 'planned' label using gh CLI
   If found, skip planning phase to avoid re-planning
   ```

3. **Create Implementation Plan**:
   ```
   Use planner agent to:
   - Analyze requirements and project context
   - Create detailed, phased implementation plan
   - Include testing strategy and risk assessment
   - Generate success criteria checklist
   ```

4. **Update Issue**:
   ```
   Use issue-updater agent to:
   - Add plan as a comment on the GitHub issue
   - Add 'planned' label to the issue
   - Update issue status to "In Progress" if using project boards
   - Create any missing labels if needed
   ```

### Phase 2: Implementation

5. **Execute Implementation**:
   ```
   Use coder agent (or specialized variant) to:
   - Create feature branch
   - Implement according to plan
   - Make atomic commits
   - Run tests and linting
   - Handle any implementation challenges
   ```

### Phase 3: Pull Request

6. **Prepare PR**:
   ```
   Use pr-preparer agent to:
   - Ensure all changes are committed
   - Verify branch and commit compliance
   - Create professional PR description
   - Push changes and create PR
   ```

### Phase 4: Monitoring & Completion

7. **Monitor PR Checks**:
   ```
   Use pr-check-monitor agent to:
   - Watch all PR status checks
   - Automatically delegate fixes for failures
   - Continue until all checks pass
   ```

8. **Update Issue Status**:
   ```
   Use issue-updater agent to:
   - Update issue status to "Done"
   - Add completion comment
   ```

## Agent Coordination

The main orchestrator follows this logic:

```python
# Pseudo-code for orchestration
def coder_command(issue_url=None):
    # Phase 1: Requirements & Planning
    requirements = Task(
        description="Analyze requirements",
        prompt=f"Analyze requirements for {issue_url or 'next logical issue'}",
        subagent_type="requirements-analyzer"
    )
    
    if not has_existing_plan(requirements.issue_number):
        plan = Task(
            description="Create implementation plan",
            prompt=f"Create plan based on: {requirements}",
            subagent_type="planner"
        )
        
        Task(
            description="Update issue with plan",
            prompt=f"Add plan to issue #{requirements.issue_number}: {plan}",
            subagent_type="issue-updater"
        )
    
    # Phase 2: Implementation
    Task(
        description="Implement feature",
        prompt=f"Implement issue #{requirements.issue_number} using the plan",
        subagent_type="coder"
    )
    
    # Phase 3: Pull Request
    pr_info = Task(
        description="Prepare pull request",
        prompt="Prepare PR for review and submission",
        subagent_type="pr-preparer"
    )
    
    # Phase 4: Monitoring
    Task(
        description="Monitor PR checks",
        prompt=f"Monitor PR #{pr_info.pr_number} and fix any failing checks",
        subagent_type="pr-check-monitor"
    )
    
    # Final status update
    Task(
        description="Update issue status",
        prompt=f"Update issue #{requirements.issue_number} status to Done",
        subagent_type="issue-updater"
    )
```

## Key Requirements

- **Always use agents** - Never perform tasks directly; delegate to specialized agents
- **Check for existing plans** - Avoid re-planning already planned issues
- **Maintain status updates** - Keep GitHub issues and project boards current
- **Ensure PR quality** - All PRs must pass checks before considering work complete
- **Follow conventions** - All agents must adhere to CLAUDE.md and project standards

## Error Handling

If any agent fails:
1. Capture the error details
2. Determine if it's recoverable
3. Either retry with adjusted parameters or report the blocker
4. Never leave work in an incomplete state

## Available Agents

- **requirements-analyzer**: Fetches and analyzes GitHub issues
- **planner**: Creates comprehensive implementation plans
- **issue-updater**: Updates GitHub issues with progress
- **coder**: Implements features and fixes
- **pr-preparer**: Prepares PRs for submission
- **pr-check-monitor**: Monitors and fixes PR check failures

Additional specialized coders may be available for specific technologies or patterns.