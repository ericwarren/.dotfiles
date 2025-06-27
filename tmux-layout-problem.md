# tmux Layout Problem - Conversation Summary

## Goal
Create a 3-pane tmux layout:
- **Left side**: 60% width, split vertically (70% neovim top, 30% small terminal bottom)
- **Right side**: 40% width, full height (Claude Code)

## Problem
Cannot get tmux to split the LEFT column. Every approach splits the RIGHT column instead.

## Context
- Switching from zellij to tmux + tmuxinator
- Updated Neovim dotnet.lua integration 
- tmuxinator had timing issues with layouts
- Moved to pure tmux script approach

## What We've Tried

### 1. tmuxinator with main-vertical layout
```yaml
layout: main-vertical
main-pane-size: 60
```
**Result**: Timing issues, inconsistent layouts

### 2. tmuxinator with post hooks
```yaml
post:
  - tmux resize-pane -t 2 -y 30%
```
**Result**: Commands didn't execute or executed too early

### 3. Pure tmux script - Horizontal first, then vertical
```bash
tmux split-window -h -p 40    # Create left|right (60%|40%)
tmux select-pane -t 0         # Select left pane  
tmux split-window -v -p 30    # Split left pane vertically
```
**Result**: Always splits right pane instead of left

### 4. Pure tmux script - Vertical first, then horizontal  
```bash
tmux split-window -v -p 30    # Create top|bottom (70%|30%)
tmux select-pane -t 0         # Select top pane
tmux split-window -h -p 40    # Split top pane horizontally  
```
**Result**: Creates 2 rows instead of desired layout

### 5. Command chaining approach
```bash
tmux new-session -d -s "$PROJECT_NAME" \; \
  split-window -h -p 40 \; \
  select-pane -t 0 \; \
  split-window -v -p 30 \; \
  select-pane -t 0
```
**Result**: Still splits right column

### 6. Layout + resize approach
```bash
tmux new-session -d -s "$PROJECT_NAME" \; \
  split-window \; \
  split-window \; \
  select-layout main-vertical \; \
  resize-pane -t 0 -x 60% \; \
  select-pane -t 1 \; \
  resize-pane -y 70%
```
**Result**: STILL splits right column

## Key Discoveries
- tmux panes display as 1,2,3 but target as 0,1,2
- `tmux list-panes` shows correct pane info
- After horizontal split: pane 1 (left, ~47 cols), pane 2 (right, ~32 cols)
- Every targeting attempt (`-t 0`, `-t 1`, `-t "$SESSION:0"`, `-t "$SESSION:1"`) splits the RIGHT pane

## Current Script State
```bash
#!/bin/bash
PROJECT_NAME=${1:-dotnet-dev}

if tmux has-session -t "$PROJECT_NAME" 2>/dev/null; then
    tmux attach-session -t "$PROJECT_NAME"
    exit 0
fi

echo "Creating new .NET development session: $PROJECT_NAME"

tmux new-session -d -s "$PROJECT_NAME" -c "$PWD" \; \
  split-window -c "$PWD" \; \
  split-window -c "$PWD" \; \
  select-layout main-vertical \; \
  resize-pane -t 0 -x 60% \; \
  select-pane -t 1 \; \
  resize-pane -y 70% \; \
  select-pane -t 0 \; \
  rename-window "dev"

tmux attach-session -t "$PROJECT_NAME"
```

## Questions for Claude Opus
1. Why does tmux ALWAYS split the right column regardless of pane targeting?
2. Is there a different approach to create this specific 3-pane layout?
3. Are we misunderstanding tmux pane indexing/targeting?
4. Should we abandon the left-column split idea and use a different layout?

## Environment 
- tmux version: Latest
- OS: Linux
- Terminal: Works fine with manual tmux commands
- The layout can be created manually with resize commands after session creation

## Manual Workaround
The desired layout can be achieved manually by:
1. Creating 2-pane layout (left|right)
2. Manually running `Ctrl+a : resize-pane -y 70%` on the right panes

But we cannot automate this in a script - every targeting method splits the wrong pane.