#!/bin/bash
# session-start-compact-notice.sh のテスト
# 実行: bash .config/ai/.claude/hooks/tests/session-start-compact-notice.test.sh

HOOK="$(cd "$(dirname "$0")/.." && pwd)/session-start-compact-notice.sh"
failures=0

assert() {
  local desc="$1" ok="$2"
  if [ "$ok" = "0" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    failures=$((failures + 1))
  fi
}

# source=compact のとき: 正しい JSON を出し、exit 0
out=$(echo '{"hook_event_name":"SessionStart","source":"compact"}' | bash "$HOOK")
code=$?
assert "compact のとき exit 0 で終わる" "$([ $code -eq 0 ]; echo $?)"
echo "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null 2>&1
assert "compact のとき hookEventName が SessionStart" "$?"
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | test("/handover")' >/dev/null 2>&1
assert "compact のとき additionalContext で /handover を案内する" "$?"
echo "$out" | jq -e '.systemMessage | test("/handover")' >/dev/null 2>&1
assert "compact のとき systemMessage でユーザーにも /handover を案内する" "$?"

# compact 以外のとき: 何も出さず exit 0（SessionStart の stdout はコンテキストに入るため）
for src in startup resume clear fork; do
  out=$(echo "{\"hook_event_name\":\"SessionStart\",\"source\":\"$src\"}" | bash "$HOOK")
  code=$?
  assert "$src のとき何も出力せず exit 0" "$([ $code -eq 0 ] && [ -z "$out" ]; echo $?)"
done

# 入力が壊れている・空のとき: 何も出さず exit 0
out=$(echo 'not json' | bash "$HOOK" 2>/dev/null)
code=$?
assert "不正な JSON のとき何も出力せず exit 0" "$([ $code -eq 0 ] && [ -z "$out" ]; echo $?)"
out=$(printf '' | bash "$HOOK" 2>/dev/null)
code=$?
assert "空入力のとき何も出力せず exit 0" "$([ $code -eq 0 ] && [ -z "$out" ]; echo $?)"

echo
if [ "$failures" -eq 0 ]; then
  echo "all passed"
else
  echo "$failures failed"
  exit 1
fi
