# Claude Code Configuration

This directory contains Claude Code settings managed with GNU Stow.

## Installation

From the `~/.dotfiles` directory:
```bash
stow claude
```

## Files Managed

- `.claude/settings.json` - Claude Code settings (theme, statusline, permissions, MCP server settings)

## Files NOT Managed (intentionally excluded)

These files are user-specific or contain sensitive data and should not be version controlled:

- `.claude.json` - User preferences, MCP servers with API keys, runtime state (KEEP LOCAL)
- `.claude/.credentials.json` - API credentials (sensitive)
- `.claude/history.jsonl` - Conversation history
- `.claude/projects/` - Project-specific settings
- `.claude/file-history/` - File modification history
- `.claude/debug/` - Debug logs
- `.claude/downloads/` - Downloaded files
- `.claude/session-env/` - Session environment snapshots
- `.claude/shell-snapshots/` - Shell state snapshots
- `.claude/todos/` - Todo list data

## Notes

- `.claude.json` is kept in your home directory and NOT managed by stow (it contains API keys and personal data)
- `settings.json` contains all shareable configurations (theme, permissions, MCP enablement)
- User-level MCP servers should be configured in `~/.claude.json` (not version controlled)
- Project-level MCP servers should be configured in `.mcp.json` in the repository root
