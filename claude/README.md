# Claude Code Configuration

Portable Claude Code configuration managed with GNU Stow, so your settings,
status line, and skills follow you to every machine.

## Installation

From the `~/.dotfiles` directory:

```bash
# Ensure ~/.claude exists as a REAL directory first (see the safety note below),
# then stow:
mkdir -p ~/.claude
stow claude
```

This links into `~/.claude/`:
- `settings.json` → your settings (permissions, **status line**, enabled plugins, TUI)
- `statusline.sh` → the status line script (invoked by settings.json)
- `skills/` → your custom skills (the whole directory is symlinked into this repo)

## Status line

The status line is a script, `statusline.sh` (stowed to `~/.claude/statusline.sh`),
which `settings.json` runs via `"command": "bash ~/.claude/statusline.sh"`. It
renders `<dir>   <branch ●changes>   <model · output-style>` in color — the
change count shows only when the tree is dirty, and the style suffix only when it
isn't the default. Being part of this package it's portable like everything else;
edit the script (not a JSON-escaped one-liner) to tweak it.

## Skills

`skills/` is symlinked into this repo, so every skill you add under
`~/.claude/skills/<name>/` is written straight into the repo and version
controlled. Commit it and it's available on all machines after `stow claude`.

`agents/` and `commands/` can be added the same way — create
`claude/.claude/agents/` (or `commands/`) here, add a `.gitkeep`, and re-stow.

## Safety: stow folding

`~/.claude` also holds secrets and machine state (credentials, sessions,
history). The `mkdir -p ~/.claude` step above matters: if `~/.claude` does
**not** already exist, stow would replace the whole directory with a single
symlink into this repo, and Claude would then write your credentials and
session history straight into version control. With `~/.claude` present as a
real directory, stow only folds the *sub-paths* this package provides
(`settings.json`, `skills/`), leaving everything else local.

Do this **before** creating any skills locally; otherwise `~/.claude/skills`
already exists as a real dir and stow will report a conflict.

## Files NOT managed (intentionally excluded)

User-specific or sensitive — kept local, never version controlled (also
guarded in the repo `.gitignore`):

- `.claude.json` - User preferences, MCP servers with API keys, runtime state
- `.claude/.credentials.json` - API credentials (sensitive)
- `.claude/settings.local.json` - Machine-local setting overrides
- `.claude/history.jsonl` - Conversation history
- `.claude/projects/` - Per-project session transcripts and memory
- `.claude/sessions/`, `.claude/session-env/` - Session state
- `.claude/shell-snapshots/` - Shell state snapshots
- `.claude/todos/` - Todo list data
- `.claude/file-history/`, `.claude/debug/`, `.claude/downloads/` - Runtime data

## Notes

- Project-level MCP servers go in `.mcp.json` at a repo root (this repo has one).
- User-level MCP servers live in `~/.claude.json` (kept local, not managed here).
