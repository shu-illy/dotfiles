#!/usr/bin/env bash
input=$(cat)

# ---- colors (ANSI via printf) ----
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
BLUE="\033[34m"
RED="\033[31m"
WHITE="\033[37m"

# ---- extract fields ----
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
output_style=$(echo "$input" | jq -r '.output_style.name // "default"')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')

# ---- git branch (skip optional locks) ----
git_branch=""
if [[ -n "$cwd" ]]; then
  git_branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
fi
# worktree branch overrides if present
[[ -n "$worktree_branch" ]] && git_branch="$worktree_branch"

# ---- shorten cwd (replace $HOME with ~) ----
home="$HOME"
display_cwd="${cwd/#$home/\~}"

# ---- build output ----
parts=()

# cwd + git branch
if [[ -n "$display_cwd" ]]; then
  if [[ -n "$git_branch" ]]; then
    parts+=("$(printf "${BOLD}${CYAN}%s${RESET} ${DIM}${GREEN}(%s)${RESET}" "$display_cwd" "$git_branch")")
  else
    parts+=("$(printf "${BOLD}${CYAN}%s${RESET}" "$display_cwd")")
  fi
fi

# model
[[ -n "$model" ]] && parts+=("$(printf "${WHITE}%s${RESET}" "$model")")

# context remaining %
if [[ -n "$remaining" ]]; then
  pct=$(printf "%.0f" "$remaining")
  if (( pct <= 20 )); then
    color="$RED"
  elif (( pct <= 50 )); then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  parts+=("$(printf "${color}ctx:${pct}%%${RESET}")")
fi

# effort level
if [[ -n "$effort" ]]; then
  parts+=("$(printf "${MAGENTA}effort:%s${RESET}" "$effort")")
fi

# output style (only when not default)
if [[ -n "$output_style" && "$output_style" != "default" ]]; then
  parts+=("$(printf "${DIM}style:%s${RESET}" "$output_style")")
fi

# rate limits
rate_parts=()
[[ -n "$five_hour" ]] && rate_parts+=("5h:$(printf '%.0f' "$five_hour")%")
[[ -n "$seven_day" ]] && rate_parts+=("7d:$(printf '%.0f' "$seven_day")%")
if [[ ${#rate_parts[@]} -gt 0 ]]; then
  rate_str="${rate_parts[*]}"
  parts+=("$(printf "${YELLOW}${rate_str// / }${RESET}")")
fi

# agent name
[[ -n "$agent_name" ]] && parts+=("$(printf "${BLUE}agent:%s${RESET}" "$agent_name")")

# vim mode
if [[ -n "$vim_mode" ]]; then
  case "$vim_mode" in
    INSERT)      vm_color="$GREEN" ;;
    NORMAL)      vm_color="$CYAN" ;;
    VISUAL*)     vm_color="$MAGENTA" ;;
    *)           vm_color="$WHITE" ;;
  esac
  parts+=("$(printf "${BOLD}${vm_color}[%s]${RESET}" "$vim_mode")")
fi

# ---- print with separator ----
sep="$(printf " ${DIM}|${RESET} ")"
result=""
for part in "${parts[@]}"; do
  if [[ -z "$result" ]]; then
    result="$part"
  else
    result="${result}${sep}${part}"
  fi
done

printf "%b\n" "$result"
