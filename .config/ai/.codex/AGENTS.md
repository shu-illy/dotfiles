## 開発ルール

### PR 作成

- YOU MUST: PR 作成を指示された時に、リポジトリ内に @.github/PULL_REQUEST_TEMPLATE.md ファイルがあれば、必ずそのフォーマットに従うようにしてください。
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

### テスト駆動開発(TDD)

- 機能実装を行う際には t_wada 氏が推奨する TDD に従って進めてください。
- https://t-wada.hatenablog.jp/

### その他

- IMPORTANT: セキュリティベストプラクティスに従う
- YOU MUST: 回答を求められた時は、日本語で出力する

@/Users/shuheiiriyama/.codex/RTK.md
