#!/usr/bin/env bash
# Claude Code status line:  <dir>   <branch ●changes>   <model · style>
# Reads the status JSON from stdin (see Claude Code status line docs).

input=$(cat)

# --- directory (basename) ---
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "."')
dir=$(basename "$cwd")

# --- model + output style ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // "?"')
style=$(printf '%s' "$input" | jq -r '.output_style.name // "default"')

# --- git branch + changed-file count ---
git_seg=""
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
    changes=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | grep -c .)
    if [ "$changes" -gt 0 ]; then
        # yellow branch + red ●count when the tree is dirty
        git_seg=$(printf '   \033[1;33m%s \033[0;31m●%s\033[0m' "$branch" "$changes")
    else
        git_seg=$(printf '   \033[1;33m%s\033[0m' "$branch")
    fi
fi

# --- model segment; append the output style when it isn't the default ---
if [ -n "$style" ] && [ "$style" != "default" ] && [ "$style" != "null" ]; then
    model_seg=$(printf '\033[1;35m%s\033[0m \033[2m· %s\033[0m' "$model" "$style")
else
    model_seg=$(printf '\033[1;35m%s\033[0m' "$model")
fi

printf '\033[1;36m%s\033[0m%s   %s' "$dir" "$git_seg" "$model_seg"
