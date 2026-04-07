---
name: worktree-summary
description: アクティブな git worktree の一覧と作業概要を収集し、Slack に通知する。複数の worktree を並行して進めている際に、各 worktree の状況を一目で把握するために使う。
allowed-tools: Bash(git *) Bash(gh *) Bash(curl *) Bash(echo *) Read Grep Glob
user-invocable: true
argument-hint: ""
---

# Worktree Summary & Slack Notification

アクティブな git worktree の作業状況を収集し、Slack に通知する。

## 手順

### 1. Worktree 一覧の取得

```bash
git worktree list
```

### 2. 各 worktree の情報収集

各 worktree に対して以下を取得する:

- **ブランチ名**: `git -C <path> branch --show-current`
- **最新コミット 3 件**: `git -C <path> log --oneline -3 --format="%h %s" --no-decorate`
- **未コミット変更の有無**: `git -C <path> status --short` の出力行数
- **ブランチの作業概要**: 最新コミットメッセージから推測し、1 行で要約
- **関連 PR**: `gh pr list --head <branch-name> --json number,title,url,state --limit 1` で該当ブランチの PR を取得。PR が存在する場合はタイトルと URL を含める

### 3. サマリーの作成

以下のフォーマットで整形する:

```
Git Worktree サマリー (YYYY-MM-DD HH:MM)
==========================================

[1/N] feature/xxx
  パス: /path/to/worktree
  概要: XXXの機能実装
  状態: 未コミット変更 3 件
  PR: #123 PRタイトル (OPEN) - https://github.com/org/repo/pull/123
  最新コミット:
    - abc1234 コミットメッセージ1
    - def5678 コミットメッセージ2
    - ghi9012 コミットメッセージ3

[2/N] fix/yyy
  ...
```

### 4. Slack への通知

以下の環境変数を使って Slack に通知する:

| 環境変数 | 必須 | 説明 |
|---------|------|------|
| `SLACK_WEBHOOK_URL` | Yes | Slack Incoming Webhook URL |
| `SLACK_REPORT_CHANNEL` | No | 送信先チャンネル (例: `#dev-worktree`)。未設定の場合は `t_iriyama` チャンネルに送信される |

- `SLACK_WEBHOOK_URL` が未設定の場合はサマリーを画面に表示して終了し、「SLACK_WEBHOOK_URL 環境変数を設定してください」と案内する
- `SLACK_REPORT_CHANNEL` が設定されている場合は JSON ペイロードに `"channel": "$SLACK_REPORT_CHANNEL"` を追加する
- Slack メッセージは Block Kit 形式で見やすく整形する

Slack 送信コマンド例:

```bash
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

### 5. Slack メッセージの JSON 構造

以下の Block Kit 構造で送信する:

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "Git Worktree サマリー (日付)"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*リポジトリ:* repo-name\n*アクティブ worktree:* N 件"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*`branch-name`*\n概要: 作業内容の要約\n状態: :large_green_circle: クリーン / :large_orange_circle: 未コミット変更 N 件\nPR: <https://github.com/org/repo/pull/123|#123 PRタイトル> (:large_green_circle: OPEN)\n```\nabc1234 コミットメッセージ\ndef5678 コミットメッセージ\n```"
      }
    }
  ]
}
```

## 注意事項

- worktree パスの最後のディレクトリ名ではなくブランチ名を表示に使う
- main/master ブランチの worktree も含める
- コミットメッセージが長い場合は 50 文字で切り詰める
- Slack Webhook のレスポンスが "ok" 以外の場合はエラーを報告する
- PR が存在しないブランチ (main 含む) では PR 行を省略する
- PR の state に応じて絵文字を使い分ける: OPEN → `:large_green_circle:`, MERGED → `:large_purple_circle:`, CLOSED → `:large_red_circle:`
