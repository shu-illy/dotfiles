## 開発ルール

## 言語設定

**重要** Claude Code は必ず日本語で回答してください。技術用語は必要に応じて英語のまま使用可能です

### PR 作成

- YOU MUST: PR 作成を指示された時に、リポジトリ内に @.github/PULL_REQUEST_TEMPLATE.md ファイルがあれば、必ずそのフォーマットに従うようにしてください。
- YOU MUST: PR 作成時は必ず assignee に `shu-illy` を設定してください（`gh pr create --assignee shu-illy`。設定し忘れた場合は `gh pr edit <番号> --add-assignee shu-illy`）。

### テスト駆動開発(TDD)

- 機能実装を行う際には t_wada 氏が推奨する TDD に従って進めてください。
- https://t-wada.hatenablog.jp/

### その他

- IMPORTANT: セキュリティベストプラクティスに従う
- テストケースの説明文は日本語で各こと

## Codex 連携ガイド

> **IMPORTANT**: Codex との連携は任意ではなく、以下のタイミングでは**必須**です。スキップしないでください。

**責務分担の原則**: コーディングを伴うタスクは、Claude Code が設計・タスク分解・レビューを担当し、実装（コードを書く作業）は Codex に任せる。Claude Code 自身が直接コードを書くのは、責務分担が不要な軽微な修正（typo・設定値変更等）に限る。

### 必須タイミング（これらは必ず Codex に問い合わせる）

- **エラー・詰まり**: 原因が分からない場合はすぐに Codex に相談する（自力で唸るより先）
- **前提確認**: 自分の解釈・前提が正しいか確認する（思い込みが多い場面ほど必須）
- **技術選定**: ライブラリ・手法を選ぶ前に必ず比較検討させる

### 実践ガイド

- 前提確認・技術選定の比較検討は `/codex:rescue "<質問内容>"` で行う（自然文で「Codexに相談して」と言っても起動する）。デフォルトで `--write`（書き込み可）が付与されるため、調査のみが目的の場合は「read-onlyで」「調査だけで」等、read-only を明示すること
- **実装委譲**: 設計・対象ファイル・TDD方針（t_wada氏推奨）を明記した実装指示を `/codex:rescue "<実装指示>"` で渡し、Codexに実装させる（デフォルトの `--write` のまま、read-only にしない）
  - 完了後は Claude Code が diff をレビューし（`/codex:review` や `/codex:adversarial-review` も活用可）、問題があれば `/codex:rescue --resume "<修正指示>"` で Codex に手戻しさせる
  - Claude Code 自身は実装フェーズで直接コードを書かない
- エラー・詰まり時の深掘り調査は `/codex:rescue --background investigate why ...` で開始 → `/codex:status` で進捗確認 → `/codex:result` で結果取得。中断する場合は `/codex:cancel`
- 前回の続きから相談する場合は `/codex:rescue --resume ...`
- コードのレビューは `/codex:review`（通常レビュー）または `/codex:adversarial-review`（前提・トレードオフを批判的に問うレビュー）
- セッションを引き継ぐ場合は `/codex:transfer`
- 導入・認証状態の確認は `/codex:setup`
- Codex の意見を鵜呑みにせず、1 意見として判断。聞き方を変えて多角的な意見を抽出

### 活用場面（上記必須タイミング以外でも積極的に使う）

1. **実現不可能な依頼**: Claude Code では実現できない要求への対処 (例: `/codex:rescue "今日の天気は？"`)
2. **前提確認**: ユーザー、Claude 自身に思い込みや勘違い、過信がないかどうか逐一確認 (例: `/codex:rescue "この前提は正しいか？"`）
3. **技術調査**: 最新情報・エラー解決・ドキュメント検索・調査方法の確認（例: `/codex:rescue "Rails 7.2の新機能を調べて"`）
4. **設計検証**: アーキテクチャ・実装方針の妥当性確認（例: `/codex:adversarial-review`で「この設計パターンは適切か？」を問う）
5. **コードレビュー**: 品質・保守性・パフォーマンスの評価（例: `/codex:review`で「このコードの改善点は？」）
6. **計画立案**: タスクの実行計画レビュー・改善提案（例: `/codex:review`で「この実装計画の問題点は？」）
7. **技術選定**: ライブラリ・手法の比較検討 （例: `/codex:rescue "このライブラリは他と比べてどうか？"`）

@RTK.md
