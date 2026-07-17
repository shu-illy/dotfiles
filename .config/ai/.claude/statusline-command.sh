#!/usr/bin/env bash
input=$(cat)

# ---- config ----
# USD -> JPY conversion rate for cost display. Update as needed; there is no
# live FX source available to the statusline, so this is a fixed estimate.
USD_JPY_RATE=155

# ---- colors (ANSI via printf; kept subdued since Claude Code renders the
# status line dimmed already) ----
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
WHITE="\033[37m"
RED="\033[31m"

# ---- extract fields ----
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
# NOTE: `cost` is not documented in every Claude Code schema revision. Pull it
# defensively so a missing/renamed field simply blanks the cost segment
# instead of breaking the whole status line.
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# ---- repo/dir name ----
if [[ -z "$repo_name" ]]; then
  base_dir="${project_dir:-$cwd}"
  [[ -n "$base_dir" ]] && repo_name=$(basename "$base_dir")
fi

# ---- git branch (skip optional locks) ----
git_branch=""
lookup_dir="${cwd:-$project_dir}"
if [[ -n "$lookup_dir" ]]; then
  git_branch=$(git --no-optional-locks -C "$lookup_dir" symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks -C "$lookup_dir" rev-parse --short HEAD 2>/dev/null || true)
fi
[[ -n "$worktree_branch" ]] && git_branch="$worktree_branch"

# ---- line 1: model [effort] ▸ repo ⎇ branch ----
line1_parts=()

if [[ -n "$model" ]]; then
  if [[ -n "$effort" ]]; then
    line1_parts+=("$(printf "${BOLD}${WHITE}%s ${MAGENTA}[%s]${RESET}" "$model" "$effort")")
  else
    line1_parts+=("$(printf "${BOLD}${WHITE}%s${RESET}" "$model")")
  fi
fi

if [[ -n "$repo_name" ]]; then
  if [[ -n "$git_branch" ]]; then
    line1_parts+=("$(printf "${CYAN}%s${RESET} ${DIM}⎇ %s${RESET}" "$repo_name" "$git_branch")")
  else
    line1_parts+=("$(printf "${CYAN}%s${RESET}" "$repo_name")")
  fi
fi

sep="$(printf " ${DIM}▸${RESET} ")"
line1=""
for part in "${line1_parts[@]}"; do
  if [[ -z "$line1" ]]; then
    line1="$part"
  else
    line1="${line1}${sep}${part}"
  fi
done

# ---- line 2: context gauge ▸ rate limits ▸ cost / duration ----
line2_parts=()

# context gauge (10 blocks)
if [[ -n "$used" ]]; then
  pct=$(printf "%.0f" "$used")
  filled=$(( pct / 10 ))
  (( filled > 10 )) && filled=10
  (( filled < 0 )) && filled=0
  empty=$(( 10 - filled ))
  if (( pct >= 80 )); then
    gauge_color="$RED"
  elif (( pct >= 50 )); then
    gauge_color="$YELLOW"
  else
    gauge_color="$GREEN"
  fi
  gauge=""
  for ((i = 0; i < filled; i++)); do gauge+="●"; done
  for ((i = 0; i < empty; i++)); do gauge+="○"; done
  line2_parts+=("$(printf "${gauge_color}%s %s%%${RESET}" "$gauge" "$pct")")
fi

# 5h rate limit + reset time (macOS: date -r for epoch seconds)
if [[ -n "$five_hour" ]]; then
  five_pct=$(printf "%.0f" "$five_hour")
  if [[ -n "$five_reset" ]]; then
    five_reset_int=$(printf "%.0f" "$five_reset")
    reset_time=$(date -r "$five_reset_int" "+%H:%M" 2>/dev/null || true)
  fi
  if [[ -n "$reset_time" ]]; then
    line2_parts+=("$(printf "${YELLOW}5h: %s%% ↺%s${RESET}" "$five_pct" "$reset_time")")
  else
    line2_parts+=("$(printf "${YELLOW}5h: %s%%${RESET}" "$five_pct")")
  fi
fi

# 7d rate limit
if [[ -n "$seven_day" ]]; then
  seven_pct=$(printf "%.0f" "$seven_day")
  line2_parts+=("$(printf "${YELLOW}7d: %s%%${RESET}" "$seven_pct")")
fi

# cumulative cost (converted to JPY) / elapsed working time
if [[ -n "$cost_usd" ]]; then
  jpy_raw=$(awk -v c="$cost_usd" -v r="$USD_JPY_RATE" 'BEGIN{printf "%.0f", c*r}')
  # add thousands separators without relying on printf %'d (unsupported on macOS bash)
  jpy=$(echo "$jpy_raw" | rev | sed -E 's/([0-9]{3})/\1,/g' | sed -E 's/,$//' | rev)
  cost_str="¥${jpy}"
  if [[ -n "$duration_ms" ]]; then
    dur_str=$(awk -v ms="$duration_ms" 'BEGIN{
      total_min = int(ms / 60000);
      h = int(total_min / 60);
      m = total_min % 60;
      if (h > 0) printf "%dh%02dm", h, m; else printf "%dm", m;
    }')
    line2_parts+=("$(printf "${GREEN}%s / %s${RESET}" "$cost_str" "$dur_str")")
  else
    line2_parts+=("$(printf "${GREEN}%s${RESET}" "$cost_str")")
  fi
fi

line2=""
for part in "${line2_parts[@]}"; do
  if [[ -z "$line2" ]]; then
    line2="$part"
  else
    line2="${line2}${sep}${part}"
  fi
done

# ---- print ----
if [[ -n "$line1" && -n "$line2" ]]; then
  printf "%b\n%b\n" "$line1" "$line2"
elif [[ -n "$line1" ]]; then
  printf "%b\n" "$line1"
else
  printf "%b\n" "$line2"
fi
