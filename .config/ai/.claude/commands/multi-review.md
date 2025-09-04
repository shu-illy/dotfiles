# コードレビューカスタムコマンド

## 概要

このカスタムコマンドは、Claude Code の複数のサブエージェントを並行で活用して、包括的なコードレビューを実行します。

## コマンド名

`multi-review`

## 説明

現在のブランチで作成している PR がある場合、その PR の差分をレビューし、コメントに投稿します。
PR がない場合、現在のブランチでの変更、または指定されたファイル・機能に対して、複数の観点から同時にコードレビューを実行します。
"staged" の引数を与えられない限り、ステージングしているファイルの差分は無視します。
レビュー結果の出力は日本語で行います。

## 実行内容

### 1. レビュー対象の特定

- Git のステータスと差分を確認
- レビュー対象を特定（staged changes, branch changes, specific files）
- ユーザーが特定のファイルや機能を指定した場合はそれを対象とする

### 2. 並行レビュー実行

以下の 3 つの専門サブエージェントを並行実行：

#### code-quality-reviewer サブエージェント

- **専門分野**: 基本品質チェック（誤字脱字、命名規則、コーディングスタイル）
- **エージェント ID**: `code-quality-reviewer`
- **詳細**: `.claude/agents/code-quality-reviewer.md` を参照

#### architecture-reviewer サブエージェント

- **専門分野**: 設計原則・アーキテクチャチェック（SOLID 原則、レイヤー構造）
- **エージェント ID**: `architecture-reviewer`
- **詳細**: `.claude/agents/architecture-reviewer.md` を参照

#### security-reviewer サブエージェント

- **専門分野**: セキュリティチェック（脆弱性、機密情報漏洩）
- **エージェント ID**: `security-reviewer`
- **詳細**: `.claude/agents/security-reviewer.md` を参照

### 3. レビュー結果の統合

- 各専門サブエージェントの結果を統合して総合的なレポートを生成
- 全観点からの優先度付けされた改善提案を提供
- クロス観点での問題の関連性を分析
- 統合された具体的なアクションプランを提示

### 4. 実行方法

このコマンドは以下の手順で動作します：

1. **対象の特定**: レビュー対象（ステージング、ファイル、機能等）を特定
2. **並行実行**: 3 つのサブエージェントを同時に実行
   - Task tool with `code-quality-reviewer` agent
   - Task tool with `architecture-reviewer` agent
   - Task tool with `security-reviewer` agent
3. **結果統合**: 各結果を統合し、総合レポートを生成
4. **アクションプラン**: 優先度付きの改善計画を提示

## 使用例

```bash
# 現在のブランチにおける変更をレビュー
claude multi-review

# ステージングしている差分をレビュー
claude multi-review staged

# 特定のファイルをレビュー
claude multi-review src/components/UserAuth.tsx

# 特定の機能をレビュー
claude multi-review "user authentication feature"

# ブランチの変更をレビュー
claude multi-review "git diff main..feature-branch"
```

## 注意事項

- レビュー結果は改善提案として参考にしてください
- セキュリティ関連の指摘については特に慎重に対応してください
- 大規模な変更の場合、レビュー時間が長くなる可能性があります
