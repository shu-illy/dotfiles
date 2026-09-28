## 開発ルール

## 言語設定

**重要** Claude Code は必ず日本語で回答してください。技術用語は必要に応じて英語のまま使用可能です

### PR 作成

- YOU MUST: PR 作成を指示された時に、リポジトリ内に @.github/PULL_REQUEST_TEMPLATE.md ファイルがあれば、必ずそのフォーマットに従うようにしてください。
- YOU MUST: PR 作成時は必ず assignee に `shu-illy` を設定してください（`gh pr create --assignee shu-illy`。設定し忘れた場合は `gh pr edit <番号> --add-assignee shu-illy`）。
- YOU MUST: 依存関係のある複数の PR を連続させる場合（上位の PR が、未マージの下位 PR の変更に依存する場合）は、GitHub の Stacked PRs（スタックされたプルリクエスト）を使ってください。
  - 参照: https://docs.github.com/ja/pull-requests/get-started/about-stacked-prs （パブリックプレビュー機能のため挙動が変わる可能性がある。ドキュメントに記載のない挙動は推測で扱わず、都度ドキュメントを確認する）
  - 前提: `gh` 2.90.0 以降（quickstart の記載）と `gh stack` 拡張（未導入なら `gh extension install github/gh-stack`）。リポジトリ側での有効化は不要
  - 構造と base の決め方:
    - 最下位の PR の base はスタックのトランク（通常は既定ブランチ `main`。リリースブランチ等も可）
    - それより上の各 PR の base は、直下の PR のブランチ
    - 例: `main ← feat/a (PR#1, base: main) ← feat/b (PR#2, base: feat/a) ← feat/c (PR#3, base: feat/b)`
    - 依存される変更（共有型・スキーマ等）を下位、依存する変更を上位のブランチに置く
    - 全ブランチが同一リポジトリにあり、1 本の線形チェーンであること（フォーク間・分岐構造は不可）
  - 作り方（非対話で実行する。`gh stack init` / `gh stack add` はブランチ名を省略すると対話プロンプトになるので必ず引数で渡す）:
    1. `gh stack init <最初のブランチ>`（トランクを `main` 以外にする場合は `gh stack init --base <トランク> <最初のブランチ>`）→ コミット。※ `init` は `git rerere` を自動で有効化する
    2. 次の論理単位ごとに、最上位ブランチ上で `gh stack add <ブランチ>` → コミット
    3. `gh stack push` でアクティブなブランチを push（`--force-with-lease`。原子的ではないため、拒否されたブランチがあれば直して再実行）
    4. 各ブランチの PR を下から順に `gh pr create --base <直下のブランチ（最下位はトランク）> --head <ブランチ> --assignee shu-illy --title ... --body-file ...` で作成する（本文は PR テンプレートがあればそのフォーマットに従う）
    5. `gh stack sync` で、ローカルスタックの open な PR を GitHub 上のスタックとしてリンクする（open な PR が 2 つ以上あるときのみ。`sync` は PR を作成しない）
    6. `gh stack view --json` でスタックの構成と PR を確認する。非対話の `sync` はローカルとリモートのスタックが分岐していると何もせず正常終了するため、終了コードだけで成功と判断しない
    - `gh stack submit` / `gh stack link` は PR が無いブランチの PR を自動作成し、assignee を指定するオプションがない（`submit --auto` は自動生成タイトル・`--open` なしなら draft）。使う場合は作成された PR に assignee と本文を後から整えること
    - `gh stack modify`（並べ替え・再構成）、`gh stack switch`、引数なしの `gh stack submit`（対話端末では全画面エディタが開く）は対話 TUI のため、エージェントは実行せずユーザーに依頼する
  - 下位レイヤーを修正するとき: `gh stack checkout <ブランチ>` で移動してコミット → `gh stack rebase --upstack` → `gh stack push`
  - rebase の注意:
    - マージにはスタック全体の線形履歴が必須。下位への push やトランクの前進で崩れたら `gh stack rebase` → `gh stack push` で直す
    - rebase が競合したら解決して `git add` → `gh stack rebase --continue`。やり直すなら `gh stack rebase --abort`（全ブランチを rebase 前に戻す）
    - Web の「Rebase stack」（サーバー側 rebase）のコミットは署名されない。署名必須のリポジトリではローカルの `gh stack rebase` を使う
  - マージの注意:
    - マージは必ず下から。中段の PR をマージするとその下の PR もまとめてマージされる（中段だけの単独マージは不可）
    - マージする PR とその下の全 PR が、スタックのベース（通常 `main`）のブランチ保護要件（必須レビュー・必須チェック・CODEOWNERS）を満たしている必要がある
    - draft の PR はマージできない。自動マージはスタックでは非対応
    - 下位がマージされると、次の未マージ PR は自動で rebase されトランクを直接の base にする。ローカルは `gh stack sync` で同期する（`--prune` はマージ済みのローカルブランチを削除するので、削除してよい場合のみ付ける）
    - スタック内の全 PR がマージされるとスタックは完了し拡張できない（続きは新しいスタックになる）
    - `gh stack merge` は非対話端末や `--yes` では確認なしにマージするため、ユーザーの明示的な指示なしに実行しない
  - 既存ルールとの併用: スタック内の**すべての** PR に assignee `shu-illy` を設定し、PR テンプレートがあれば各 PR の本文をそのフォーマットに従って書く

### GitHub へのコメント投稿

- YOU MUST: GitHub にコメントを投稿する場合（`gh pr comment` / `gh issue comment` / レビューコメント等、手段を問わず）、**Claude からのコメントであることが分かる注記をコメント末尾に必ず付けてください**:

  ```
  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  ```

- 人間（shu-illy 本人）の発言と誤認されないようにするためのルールです。省略してよいのはオーナーが「注記なしで」と明示した場合のみ。

### テスト駆動開発(TDD)

- 機能実装を行う際には t_wada 氏が推奨する TDD に従って進めてください。
- https://t-wada.hatenablog.jp/

### その他

- IMPORTANT: セキュリティベストプラクティスに従う
- 機能の追加・改善などで設計を行う際は必ず Codex と議論を複数回重ねること
- テストケースの説明文は日本語で各こと

## Codex 連携ガイド

> **IMPORTANT**: Codex との連携は任意ではなく、以下のタイミングでは**必須**です。スキップしないでください。

### 必須タイミング（これらは必ず Codex に問い合わせる）

- **実装前**: 設計方針・アーキテクチャを決める前に必ず `/codex:rescue` で壁打ちする
- **実装計画のレビュー**: 計画を立てたら、実装開始前に `/codex:review` で Codex にレビューさせる
- **エラー・詰まり**: 原因が分からない場合はすぐに Codex に相談する（自力で唸るより先）
- **前提確認**: 自分の解釈・前提が正しいか確認する（思い込みが多い場面ほど必須）
- **技術選定**: ライブラリ・手法を選ぶ前に必ず比較検討させる

### 実践ガイド

- 壁打ち・前提確認・技術選定の比較検討は `/codex:rescue "<質問内容>"` で行う（自然文で「Codexに相談して」と言っても起動する）。デフォルトで `--write`（書き込み可）が付与されるため、壁打ち・調査のみが目的の場合は「read-onlyで」「調査だけで」等、read-only を明示すること
- エラー・詰まり時の深掘り調査は `/codex:rescue --background investigate why ...` で開始 → `/codex:status` で進捗確認 → `/codex:result` で結果取得。中断する場合は `/codex:cancel`
- 前回の続きから相談する場合は `/codex:rescue --resume ...`
- 実装計画・設計・コードのレビューは `/codex:review`（通常レビュー）または `/codex:adversarial-review`（設計・前提・トレードオフを批判的に問うレビュー）
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
