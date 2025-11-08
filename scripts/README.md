# Worktree + Tmux Scripts

Git worktree management scripts that automatically create tmux development environments with Claude Code.

## Installation

Install with stow:
```bash
cd ~/.dotfiles
stow scripts
```

## Scripts

### `wtree <branch-name> [base-branch]`
Create a new git worktree with a tmux session and Claude Code.

**Features:**
- Creates worktree in `../worktrees/<branch-name>`
- Creates new branch from base (default: HEAD)
- Launches tmux session named `<repo>-<branch>`
- Left pane: Terminal in worktree directory
- Right pane: Claude Code auto-started

**Examples:**
```bash
wtree feature-auth              # Create from current HEAD
wtree fix-bug main              # Create from main branch
wtree refactor-api develop     # Create from develop branch
```

### `wtree-ls`
List all worktrees and their associated tmux sessions.

Shows:
- All git worktrees with paths
- Associated tmux session status (active/none)
- Active tmux sessions for current repository

**Example:**
```bash
wtree-ls
```

### `wtree-attach <branch-name>`
Attach to an existing worktree's tmux session (creates session if missing).

**Example:**
```bash
wtree-attach feature-auth
```

### `wtree-rm <branch-name>`
Remove a worktree and kill its tmux session.

**Features:**
- Prompts for confirmation
- Kills associated tmux session
- Removes worktree directory
- Deletes branch

**Example:**
```bash
wtree-rm feature-auth
```

## Workflow Example

```bash
# Start new feature
wtree feature-auth

# Work in tmux session (terminal left, Claude Code right)
# ... make changes ...

# List all worktrees
wtree-ls

# Switch to another worktree
wtree-attach fix-bug

# Clean up finished work
wtree-rm feature-auth
```

## Directory Structure

```
your-repo/
├── .git/
└── ...

worktrees/                  # Created automatically
├── feature-auth/           # Worktree for feature-auth branch
├── fix-bug/                # Worktree for fix-bug branch
└── ...
```

## Tips

- Each worktree is completely isolated
- You can have multiple branches checked out simultaneously
- Tmux sessions persist across terminal restarts
- Use `Ctrl+Space` prefix for tmux commands (see ~/.tmux.conf)
- Press `Ctrl+Space d` to detach from session without closing it
