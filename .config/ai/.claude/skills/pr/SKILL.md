---
name: pr
description: PR 作成カスタムコマンド。現在のブランチの変更内容を基に GitHub プルリクエストを作成します。引数にブランチ名を渡すとそのブランチをベースブランチとして使用します。
disable-model-invocation: true
allowed-tools:
  - Bash(git branch:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git push:*)
  - Bash(git rev-parse:*)
  - Bash(gh pr create:*)
  - Bash(gh pr edit:*)
  - Read
---

## 現在のブランチ情報

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`

現在のブランチの変更内容を基に、適切な PR タイトルと説明文を生成し、GitHub でプルリクエストを作成します。

$ARGUMENTS が指定された場合、そのブランチをベースブランチとして PR を作成します。

## 実行内容

### 1. 前提条件の確認

- 現在のブランチが main ブランチや develop ブランチでないことを確認
- リモートリポジトリとの同期状態を確認
- 未コミットの変更がないことを確認
- NEVER: ステージングしていない差分ファイルは意図的にステージングしていない可能性が高いので、`git add`は実行しないこと

### 2. PR テンプレートの確認

- `.github/PULL_REQUEST_TEMPLATE.md` ファイルの存在を確認
- YOU MUST: テンプレートが存在する場合は、その内容を読み込み、PR 作成時に使用する

### 3. 変更内容の分析

- `git diff` および `git log` を使用して変更内容を分析
- コミット履歴から変更の目的と内容を理解

### 4. PR タイトルの生成

gitmoji を prefix に入れてタイトルを生成：

- `✨` - 新機能の追加
- `🐛` - バグ修正
- `📝` - ドキュメントの変更
- `💄` - コードフォーマットの変更
- `♻️` - リファクタリング
- `✅` - テストの追加・修正
- `🩹` - 重要でない問題の軽微な修正

上記以外についても、gitmoji のルールに従って適切に絵文字を設定する
<https://gitmoji.dev/>

### 5. PR 説明文の生成

- `.github/PULL_REQUEST_TEMPLATE.md`のテンプレートの構造に従って説明文を作成
- 各セクションに適切な内容を記入
- IMPORTANT: PR の description に、Claude Code により作成された PR が分かる表記を入れる
- YOU MUST: PULL_REQUEST_TEMPLATE.md ファイルに `<!-- I want to review in Japanese. -->` などのコメントが含まれる場合、それも PR の description に含めるようにすること
- IMPORTANT: 怠惰な人間が読むことを前提として、PRの内容を漏れなく伝えることよりも、PRの意図が伝わりやすく、読みやすいように要点をまとめることを重視すること。

### 6. PR の作成

- GitHub CLI を使用して PR を作成

### 7. assignee の追加

- 作成したPRのassigneeに`shu-illy`を設定
