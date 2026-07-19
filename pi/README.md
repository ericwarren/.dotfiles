# Pi Coding Agent Configuration

Portable [Pi](https://pi.dev) configuration managed with GNU Stow, so your
settings and skills follow you to every machine.

## Installation

From the `~/.dotfiles` directory:

```bash
# Ensure ~/.pi/agent exists as a REAL directory first (see the safety note
# below), then stow:
mkdir -p ~/.pi/agent
stow pi
```

This links into `~/.pi/agent/`:
- `settings.json` → global user preferences (applies to all sessions)
- `skills/` → your custom skills (the whole directory is symlinked into this repo)

## Config layout

Pi stores everything under `~/.pi/agent/` (override with `PI_CODING_AGENT_DIR`):

- `settings.json` — global settings; project overrides live in `.pi/settings.json`
- `models.json` — custom model definitions
- `AGENTS.md` — global project instructions
- `extensions/` — user extensions and themes/prompts
- `sessions/` — JSONL conversation history (local, not managed)
- `auth.json`, `trust.json`, `npm/` — credentials, trust decisions, installed
  packages (local, not managed)

`models.json`, `AGENTS.md`, and `extensions/` can be version-controlled the same
way `settings.json` is — create them under `pi/.pi/agent/` here and re-stow.

## Safety: stow folding

`~/.pi/agent` also holds secrets and machine state (`auth.json`, sessions,
trust). The `mkdir -p ~/.pi/agent` step above matters: if `~/.pi` does **not**
already exist, stow would replace the whole directory with a single symlink into
this repo, and Pi would then write your credentials and session history straight
into version control. With `~/.pi/agent` present as a real directory, stow only
folds the *sub-paths* this package provides (`settings.json`, `skills/`), leaving
everything else local.

Do this **before** creating any skills locally; otherwise `~/.pi/agent/skills`
already exists as a real dir and stow will report a conflict.

## Files NOT managed (intentionally excluded)

Sensitive or machine-local — kept local, never version controlled (also guarded
in the repo `.gitignore`):

- `auth.json` — API credentials (set via `/login`)
- `trust.json` — per-directory trust decisions
- `settings.local.json` — machine-local setting overrides
- `sessions/` — conversation history
- `npm/` — user-scoped installed packages
