// git-czの設定ファイル

const types = {
  art: {
    description: "コードの構造/形式の改善",
    emoji: "🎨",
    value: "art",
  },
  zap: {
    description: "パフォーマンス改善",
    emoji: "⚡️",
    value: "zap",
  },
  fire: {
    description: "コードやファイルの削除",
    emoji: "🔥",
    value: "fire",
  },
  bug: {
    description: "バグの修正",
    emoji: "🐛",
    value: "bug",
  },
  ambulance: {
    description: "重大なホットフィックス",
    emoji: "🚑",
    value: "ambulance",
  },
  sparkles: {
    description: "新機能の導入",
    emoji: "✨",
    value: "sparkles",
  },
  memo: {
    description: "ドキュメンテーションの追加/更新",
    emoji: "📝",
    value: "memo",
  },
  rocket: {
    description: "デプロイ",
    emoji: "🚀",
    value: "rocket",
  },
  lipstick: {
    description: "UIやスタイルファイルの追加/更新",
    emoji: "💄",
    value: "lipstick",
  },
  tada: {
    description: "プロジェクトの開始",
    emoji: "🎉",
    value: "tada",
  },
  // 他のgitmoji項目も同様に記述...
  test_tube: {
    description: "失敗するテストの追加",
    emoji: "🧪",
    value: "test_tube",
  },
  necktie: {
    description: "ビジネスロジックの追加/更新",
    emoji: "👔",
    value: "necktie",
  },
  stethoscope: {
    description: "ヘルスチェックの追加/更新",
    emoji: "🩺",
    value: "stethoscope",
  },
  bricks: {
    description: "インフラ関連の変更",
    emoji: "🧱",
    value: "bricks",
  },
  technologist: {
    description: "DX改善",
    emoji: "🧑‍💻",
    value: "technologist",
  },
  money_with_wings: {
    description: "スポンサーやお金に関するインフラの追加",
    emoji: "💸",
    value: "money_with_wings",
  },
  thread: {
    description: "マルチスレッドや並行処理に関連するコードの追加/更新",
    emoji: "🧵",
    value: "thread",
  },
  safety_vest: {
    description: "バリデーションの追加/更新",
    emoji: "🦺",
    value: "safety_vest",
  },
  messages: {
    type: 'Select the type of change that you\'re committing:',
    customScope: 'Select the scope this component affects:',
    subject: 'Write a short, imperative mood description of the change:\n',
    body: 'Provide a longer description of the change:\n ',
    breaking: 'List any breaking changes:\n',
    footer: 'Issues this commit closes, e.g #123:',
    confirmCommit: 'The packages that this commit has affected\n',
  },
}

console.log(types)

module.exports = {
  disableEmoji: false,
  format: "{type}{scope}: {emoji}{subject}",
  list: [
    "test",
    "feat",
    "fix",
    "chore",
    "docs",
    "refactor",
    "style",
    "ci",
    "perf",
  ],
  maxMessageLength: 64,
  minMessageLength: 3,
  questions: [
    "type",
    "scope",
    "subject",
    "body",
    "breaking",
    "issues",
    "lerna",
  ],
  scopes: [],
  types,
  list: Object.keys(types)
};
