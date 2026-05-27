#!/bin/bash
# PR作成後に自動でassigneeをshu-illyに設定するPostToolUse hook
#
# Claude Code の PostToolUse hook として動作する。
# gh pr create を含むBashコマンドが実行された後、
# 出力に含まれるPR URLを取得して gh pr edit --add-assignee shu-illy を実行する。

input=$(cat)

# Bashツールのみ処理
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# gh pr create を含むコマンドのみ処理
command=$(echo "$input" | jq -r '.tool_input.command // ""')
if ! echo "$command" | grep -q "gh pr create"; then
  exit 0
fi

# tool_result から PR URL を抽出
# gh pr create の stdout は "https://github.com/<owner>/<repo>/pull/<number>" の形式
tool_result=$(echo "$input" | jq -r '.tool_result // ""')
pr_url=$(echo "$tool_result" | grep -oE 'https://github\.com/[^[:space:]]+/pull/[0-9]+' | head -1)

if [ -z "$pr_url" ]; then
  exit 0
fi

# assignee を設定（エラーはstderrに出力するがhookは失敗させない）
gh pr edit "$pr_url" --add-assignee shu-illy 2>/dev/null || true

exit 0
