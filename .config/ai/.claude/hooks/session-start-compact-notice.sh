#!/bin/bash
# コンテキスト圧縮直後に /handover の実行を促す SessionStart hook
#
# Claude Code の SessionStart hook として動作する（secretary/.claude/settings.json で matcher: compact として登録）。
# 入力 JSON の source が compact のときだけ、モデル向け（additionalContext）と
# ユーザー向け（systemMessage）に通知を出す。
# SessionStart の標準出力はそのままコンテキストに入るため、それ以外のときは何も出力しない。

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

source_type=$(echo "$input" | jq -r '.source // ""' 2>/dev/null)
if [ "$source_type" != "compact" ]; then
  exit 0
fi

jq -n '{
  systemMessage: "コンテキストが圧縮されました。圧縮前に引き継ぎ書を作っていなければ /handover の実行を検討してください。",
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "直前にコンテキストの圧縮（/compact または auto-compact）が行われた。圧縮前に /handover で引き継ぎ書を作成済みなら、それを読んで作業を再開する。未作成なら、圧縮後の要約で分かる範囲で /handover を実行して引き継ぎ書を残すことを検討する。"
  }
}'
