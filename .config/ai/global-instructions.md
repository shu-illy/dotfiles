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

- YOU MUST: PR を stack する場合（ある PR のブランチを別の PR の base にする場合）は、**例外なく** GitHub の Stacked PRs 機能（`gh stack`）を使う。
- 禁止（擬似スタック）: `gh stack` を使わない base の手動付け替え / タイトル・本文に依存関係を書くだけ / PR を分割するだけ
- 参照: https://docs.github.com/ja/pull-requests/get-started/about-stacked-prs （プレビュー機能。記載のない挙動は推測せず都度確認）
- 準備: `gh extension upgrade gh-stack` で拡張を最新化（未導入なら `gh extension install github/gh-stack`）。古い版では `sync` が成功表示でもスタックが作られないことがある
- 構造: 最下位の base はトランク（通常 `main`）、上位の base は直下のブランチ。依存される変更を下位に置き、1 本の線形チェーンにする
- 手順（非対話。ブランチ名は必ず引数で渡す）:
  1. `gh stack init <ブランチ>` → コミット、以降 `gh stack add <ブランチ>` → コミット
  2. `gh stack push`
  3. PR を下から順に `gh pr create --base <直下のブランチ> --head <ブランチ> --assignee shu-illy ...`（テンプレートに従う）
  4. `gh stack sync` でリンクし、`gh stack view --json` で GitHub 上のスタックになったか確認（終了コードだけで判断しない）。できていなければ `gh stack link <下位PR番号> <上位PR番号>`
- 下位を修正: `gh stack checkout <ブランチ>` → コミット → `gh stack rebase --upstack` → `gh stack push`（競合時は解決して `gh stack rebase --continue`）
- 実行しないもの: `gh stack modify` / `switch` / 引数なし `submit`（対話 TUI。ユーザーに依頼）、`gh stack merge`（確認なしでマージされる。明示指示があるときのみ）。`submit` / `link` で PR を自動作成した場合は、assignee と本文を後から整える

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
