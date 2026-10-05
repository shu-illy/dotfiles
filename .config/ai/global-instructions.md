<!--
  Claude Code と Codex の共有グローバル指示ファイル（実体はこの 1 ファイル）。
  setup.sh が次の 2 か所からこのファイルへ symlink を張る:
    ~/.claude/CLAUDE.md  (Claude Code のユーザースコープ指示)
    ~/.codex/AGENTS.md   (Codex のグローバル指示)
  ファイル名を AGENTS.md / CLAUDE.md にしないのは、dotfiles 内で作業した際に
  プロジェクト指示として二重に読み込まれるのを避けるため。
  Codex は @import を展開しないので、他ファイルの import は使わず本文に直接書くこと。
-->

## 開発ルール

### 言語設定

- **重要**: 回答は必ず日本語で行ってください。技術用語は必要に応じて英語のまま使用可能です

### PR 作成

- YOU MUST: PR 作成を指示された時に、リポジトリ内に `.github/PULL_REQUEST_TEMPLATE.md` ファイルがあれば、必ずそのフォーマットに従うようにしてください。
- YOU MUST: PR 作成時は必ず assignee に `shu-illy` を設定してください（`gh pr create --assignee shu-illy`。設定し忘れた場合は `gh pr edit <番号> --add-assignee shu-illy`）。

### Stacked PRs

- YOU MUST: PR を stack する場合（ある PR のブランチを別の PR の base にする場合。上位の PR が未マージの下位 PR の変更に依存する場合を含む）は、**例外なく** GitHub の Stacked PRs 機能（`gh stack`）を使ってください。
- 禁止: 次のような「擬似スタック」は作らないこと。
  - `gh stack` を使わず、手動で base ブランチを付け替えるだけのもの
  - タイトルや本文に依存関係（「#123 の後にマージ」等）を書くだけのもの
  - PR を分割するだけで、GitHub 上のスタックとしてリンクしないもの

以下は上記の必須ルールに従って Stacked PRs を作る際の手順と注意点です。

- 参照: https://docs.github.com/ja/pull-requests/get-started/about-stacked-prs （パブリックプレビュー機能のため挙動が変わる可能性がある。ドキュメントに記載のない挙動は推測で扱わず、都度ドキュメントを確認する）
- 前提: `gh` 2.90.0 以降（quickstart の記載）と `gh stack` 拡張（未導入なら `gh extension install github/gh-stack`）。リポジトリ側での有効化は不要
  - スタック作業の前に必ず `gh extension upgrade gh-stack` で拡張を最新にする（自動では更新されない）。古い版（v0.0.3 で確認）では `gh stack sync` が成功と表示しても GitHub 上にスタックが作られないことがある
  - スタック作成後は GitHub 上でスタックになっているか確認する（`gh stack link` / `gh stack sync` の出力に stack 番号が出るか）。作られていなければ `gh stack link <下位PR番号> <上位PR番号>` で作る（既存 PR だけを渡せば新しい PR は作られない）
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

- YOU MUST: GitHub にコメントを投稿する場合（`gh pr comment` / `gh issue comment` / レビューコメント等、手段を問わず）、**AI エージェントからのコメントであることが分かる注記をコメント末尾に必ず付けてください**。注記には実際に使用しているエージェント名を入れる:
  - Claude Code の場合:

    ```
    🤖 Generated with [Claude Code](https://claude.com/claude-code)
    ```

  - Codex の場合:

    ```
    🤖 Generated with [Codex](https://openai.com/codex)
    ```

- 人間（shu-illy 本人）の発言と誤認されないようにするためのルールです。省略してよいのはオーナーが「注記なしで」と明示した場合のみ。

### テスト駆動開発(TDD)

- 機能実装を行う際には t_wada 氏が推奨する TDD に従って進めてください。
- https://t-wada.hatenablog.jp/

### レビュー

- 設計・実装計画・実装（コード変更）は、確定・着手・完了報告の前にサブエージェントにレビューさせてください。
- サブエージェントが使えない環境では、別のエージェント（別セッション）にレビューを依頼してください。
- レビューの指摘は鵜呑みにせず 1 意見として判断する。必要なら観点や聞き方を変えて複数回レビューさせる。

### その他

- IMPORTANT: セキュリティベストプラクティスに従う
- テストケースの説明文は日本語で書くこと

## RTK (Rust Token Killer)

- `rtk` はシェルコマンドの出力をトークン節約のために整形する CLI プロキシ。
- Codex: シェルコマンドには必ず `rtk` を前置する（例: `rtk git status` / `rtk npm run build`）。
- Claude Code: hook がコマンドを自動で `rtk` 付きに書き換えるため、手動で前置する必要はない。
- メタコマンドは直接実行する: `rtk gain`（節約量の分析）、`rtk gain --history`（履歴）、`rtk proxy <cmd>`（フィルタせず生で実行）。
