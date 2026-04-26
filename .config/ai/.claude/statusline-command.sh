#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
ctx=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

parts=()
[[ -n "$cwd" ]] && parts+=("$cwd")
[[ -n "$model" ]] && parts+=("$model")
[[ -n "$ctx" ]] && parts+=("Ctx: ${ctx}%")

IFS=" | "
echo "${parts[*]}"
