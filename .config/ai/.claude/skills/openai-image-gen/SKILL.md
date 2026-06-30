---
name: openai-image-gen
description: OpenAI GPT Image 2 (通称 ChatGPT Image 2.0) で画像を生成しローカル保存する。ユーザーが「画像生成して」「画像作って」「絵を描いて」「<内容>のイラスト作って」等、**新規画像の生成を明示的に依頼した時のみ**発火。既存画像の編集・解析・閲覧、Figma 関連の依頼では発火しない。
allowed-tools:
  - Bash(python3:*)
  - SendUserFile
user-invocable: true
argument-hint: "<prompt> [--size auto] [--quality auto] [--model gpt-image-2] [--cheap] [--n 1] [--out PATH] [--dry-run]"
---

# openai-image-gen

OpenAI の画像生成 API (`POST /v1/images/generations`、`gpt-image-*` ファミリ) を呼んで画像を生成し、ローカルファイルとして保存してから Claude Code 上で表示する。

## 前提・依存

- macOS (Darwin) / Linux
- `python3` (3.10 以降、stdlib のみ使用)
- 環境変数 `OPENAI_API_KEY` が設定済みであること
- ネットワーク到達: `api.openai.com`

## 初回セットアップ (オーナー作業)

ChatGPT のサブスク (Plus/Pro 等) とは **別** に OpenAI Platform でセットアップが必要です。

1. https://platform.openai.com にアクセスし、ChatGPT と同じメールでログイン
2. **Billing** からクレジットカードを登録し、最低 $5 程度のクレジットを購入 (または auto-recharge を設定)
3. **API keys** → "Create new secret key" → 発行されたキー (`sk-...`) をコピー
4. **Settings → Organization → Verification** で本人確認を完了 (gpt-image-* は組織検証必須。政府発行 ID 必要、即時〜数日)
5. `~/.zshrc` に追記:
   ```bash
   export OPENAI_API_KEY="sk-..."
   # 任意: デフォルトモデルを上書き
   # export OPENAI_IMAGE_MODEL="gpt-image-2"
   # 任意: 保存先を上書き
   # export OPENAI_IMAGE_OUTPUT_DIR="$HOME/Pictures/claude-gen"
   ```
6. `source ~/.zshrc` で読み込み直す

> SSL 証明書エラーが出る場合は `Applications/Python 3.x/Install Certificates.command` を一度実行する (macOS 標準・mise の Python では通常不要)

## トリガーと発火条件

**発火する例:**

- 「猫の画像を生成して」「夕焼けの絵を描いて」「アイコン作って」
- 「<日本語の内容> のイラストお願い」「create an image of ...」
- `/openai-image-gen <prompt>` の明示呼び出し

**発火しない例 (別スキル/別ツールに任せる):**

- 既存画像ファイルを Read して内容を尋ねるケース
- Figma での画面/コンポーネント作成 (→ `figma-*` スキル)
- 画像の編集・バリエーション生成 (本スキルは generations 専用)

## 使い方

### 基本

```bash
python3 ~/.claude/skills/openai-image-gen/scripts/generate.py \
  --prompt "a corgi astronaut floating in space, watercolor"
```

### よく使うオプション

| オプション | デフォルト | 説明 |
|---|---|---|
| `--prompt <text>` | 必須 | 画像プロンプト。英語推奨だが日本語も可 |
| `--model <id>` | `gpt-image-2` | `$OPENAI_IMAGE_MODEL` で上書き可 |
| `--size <s>` | `auto` | `1024x1024` / `1024x1536` / `1536x1024` / `2048x2048` / `2048x1152` / `3840x2160` / `2160x3840` / `auto` |
| `--quality <q>` | `auto` | `low` / `medium` / `high` / `auto` |
| `--n <int>` | `1` | 生成枚数。5 以上は `--yes` 必須 |
| `--output-format` | `png` | `png` / `jpeg` / `webp` |
| `--out <path>` | 自動 | `n=1` ならファイル、`n>1` ならディレクトリ |
| `--cheap` | off | `gpt-image-1-mini` + `quality=low` 強制 (約 $0.005/枚) |
| `--dry-run` | off | API を叩かずリクエスト body と保存予定パスを表示 |

### 保存先

デフォルト: `~/Pictures/claude-gen/YYYY-MM-DD/<HHMMSS>-<slug>.<ext>`

`$OPENAI_IMAGE_OUTPUT_DIR` で常時上書き可。

### コスト目安 (1 枚あたり, USD)

| モデル | low | medium | high |
|---|---|---|---|
| `gpt-image-2` | $0.005〜$0.04 | $0.02〜$0.10 | $0.05〜$0.211 |
| `gpt-image-1.5` | $0.009〜$0.04 | $0.02〜$0.10 | $0.05〜$0.20 |
| `gpt-image-1` | $0.011〜$0.04 | $0.04〜$0.16 | $0.07〜$0.25 |
| `gpt-image-1-mini` | $0.005〜$0.015 | $0.015〜$0.03 | $0.03〜$0.052 |

(サイズが大きいほど・quality が高いほどレンジ上限。詳細は https://openai.com/api/pricing/ を参照)

## Claude Code 側の手順 (このスキル発火時)

1. ユーザー入力からプロンプトとオプションを組み立てる
2. 上記コマンドを `Bash` で実行
3. **コマンド成功時**: stdout 末尾の `SAVED:<absolute-path>` 行 (複数の場合あり) をパースし、**必ず `SendUserFile`** を使って各画像をユーザーに表示する:
   - `files`: SAVED で得た絶対パスのリスト
   - `status`: `normal` (明示依頼への応答)
   - `caption`: プロンプトの要約 1 行 (例: `a corgi astronaut`)
4. `SendUserFile` が利用不可な環境では、フォールバックとしてマークダウン画像記法 `![<caption>](file:///<abs-path>)` で出力
5. **コマンド失敗時 (exit code 別の対応):**
   - `2` (認証): `OPENAI_API_KEY` が未設定/無効。`~/.zshrc` の設定を案内
   - `3` (レート制限): stderr の `Retry-After` 値があれば「N 秒後に再試行してください」と案内
   - `4` (ポリシー違反): プロンプトを言い換えるよう促す。違反プロンプトはログに残さない
   - `5` (タイムアウト): `--quality low` または小さい `--size` で再試行を提案
   - `6` (組織検証未完了): 組織検証 (本人確認) の手順を案内
   - `1` (汎用): stderr 内容をそのまま見せる

## 例

### 1 枚生成 (デフォルト)

```bash
python3 ~/.claude/skills/openai-image-gen/scripts/generate.py \
  --prompt "minimalist logo of a coffee bean, flat design"
# → SAVED:/Users/shilly/Pictures/claude-gen/2026-06-08/143022-minimalist-logo-of-a-coffee-bean-flat-d.png
```

### 安く 3 枚生成して見比べる

```bash
python3 ~/.claude/skills/openai-image-gen/scripts/generate.py \
  --prompt "isometric office desk illustration" --n 3 --cheap
```

### キー未取得 / 経路確認

```bash
python3 ~/.claude/skills/openai-image-gen/scripts/generate.py \
  --prompt "a cat in space" --dry-run
```

## セキュリティ

- API キーは `$OPENAI_API_KEY` のみから読む。スクリプト・SKILL.md にハードコード厳禁
- `--dry-run` 出力では `Authorization` ヘッダを `Bearer ***` に伏字化
- 保存ディレクトリは `mode=0o700` (本人のみアクセス可) で作成
- 生成画像は `~/Pictures/claude-gen/` 配下に置かれ、いずれの git リポジトリにも含まれない

## 制約・既知の注意点

- gpt-image-* 系は **b64_json のみ返却** (URL 返却はサポートされない)。スクリプトが自動で base64 デコードしてファイル化する
- HTTP タイムアウト 120 秒。`gpt-image-2 high quality` は 30〜60 秒かかることがある
- 組織検証 (Organization Verification) が gpt-image 系で必須なケースがある (403 で判別)
- `n > 1` のときは API が複数枚分の課金を行う。コスト警告は `n > 4` のときに表示
- モデル ID (`gpt-image-2` 等) は将来 OpenAI 側で deprecation の可能性あり。`$OPENAI_IMAGE_MODEL` で逃げ道を確保している

## 参考

- API リファレンス: https://platform.openai.com/docs/api-reference/images
- 価格表: https://openai.com/api/pricing/
- スクリプト本体: `~/.claude/skills/openai-image-gen/scripts/generate.py`
