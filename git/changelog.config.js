// git-czの設定ファイル

const types = {
  art: {
    description: 'コードの構造/形式の改善 | Improve structure/format of the code',
    emoji: '🎨',
    value: 'art'
  },
  zap: {
    description: 'パフォーマンス改善 | Improve performance',
    emoji: '⚡️',
    value: 'zap'
  },
  fire: {
    description: 'コードやファイルの削除 | Remove code or files',
    emoji: '🔥',
    value: 'fire'
  },
  bug: {
    description: 'バグの修正 | Fix a bug',
    emoji: '🐛',
    value: 'bug'
  },
  ambulance: {
    description: '重大なホットフィックス | Critical hotfix',
    emoji: '🚑',
    value: 'ambulance'
  },
  sparkles: {
    description: '新機能の導入 | Introduce new features',
    emoji: '✨',
    value: 'sparkles'
  },
  memo: {
    description: 'ドキュメンテーションの追加/更新 | Add or update documentation',
    emoji: '📝',
    value: 'memo'
  },
  rocket: {
    description: 'デプロイ | Deploy stuff',
    emoji: '🚀',
    value: 'rocket'
  },
  lipstick: {
    description: 'UIやスタイルファイルの追加/更新 | Add or update the UI and style files',
    emoji: '💄',
    value: 'lipstick'
  },
  tada: {
    description: 'プロジェクトの開始 | Begin a project',
    emoji: '🎉',
    value: 'tada'
  },
  white_check_mark: {
    description: 'テストの追加/更新/合格 | Add, update, or pass tests',
    emoji: '✅',
    value: 'white_check_mark'
  },
  lock: {
    description: 'セキュリティやプライバシーに関する問題の修正 | Fix security or privacy issues',
    emoji: '🔒️',
    value: 'lock'
  },
  closed_lock_with_key: {
    description: 'シークレットの追加/更新 | Add or update secrets',
    emoji: '🔐',
    value: 'closed_lock_with_key'
  },
  bookmark: {
    description: 'リリース/バージョンタグ | Release/Version tags',
    emoji: '🔖',
    value: 'bookmark'
  },
  rotating_light: {
    description: 'コンパイラ/リンターの警告を修正 | Fix compiler/linter warnings',
    emoji: '🚨',
    value: 'rotating_light'
  },
  construction: {
    description: '作業中 | Work in progress',
    emoji: '🚧',
    value: 'construction'
  },
  green_heart: {
    description: 'CIビルドの修正 | Fix CI Build',
    emoji: '💚',
    value: 'green_heart'
  },
  arrow_down: {
    description: '依存関係のダウングレード | Downgrade dependencies',
    emoji: '⬇️',
    value: 'arrow_down'
  },
  arrow_up: {
    description: '依存関係のアップグレード | Upgrade dependencies',
    emoji: '⬆️',
    value: 'arrow_up'
  },
  pushpin: {
    description: '依存関係を特定のバージョンに固定 | Pin dependencies to specific versions',
    emoji: '📌',
    value: 'pushpin'
  },
  construction_worker: {
    description: 'CIビルドシステムの追加/更新 | Add or update CI build system',
    emoji: '👷',
    value: 'construction_worker'
  },
  chart_with_upwards_trend: {
    description: '分析またはトラッキングコードの追加/更新 | Add or update analytics or track code',
    emoji: '📈',
    value: 'chart_with_upwards_trend'
  },
  recycle: {
    description: 'コードのリファクタリング | Refactor code',
    emoji: '♻️',
    value: 'recycle'
  },
  heavy_plus_sign: {
    description: '依存関係の追加 | Add a dependency',
    emoji: '➕',
    value: 'heavy_plus_sign'
  },
  heavy_minus_sign: {
    description: '依存関係の削除 | Remove a dependency',
    emoji: '➖',
    value: 'heavy_minus_sign'
  },
  wrench: {
    description: '設定ファイルの追加/更新 | Add or update configuration files',
    emoji: '🔧',
    value: 'wrench'
  },
  hammer: {
    description: '開発スクリプトの追加/更新 | Add or update development scripts',
    emoji: '🔨',
    value: 'hammer'
  },
  globe_with_meridians: {
    description: '多言語対応 | Internationalization and localization',
    emoji: '🌐',
    value: 'globe_with_meridians'
  },
  pencil2: {
    description: '誤字の修正 | Fix typos',
    emoji: '✏️',
    value: 'pencil2'
  },
  poop: {
    description: '改善が必要な悪いコード | Write bad code that needs to be improved',
    emoji: '💩',
    value: 'poop'
  },
  rewind: {
    description: '変更を元に戻す | Revert changes',
    emoji: '⏪',
    value: 'rewind'
  },
  twisted_rightwards_arrows: {
    description: 'ブランチをマージ | Merge branches',
    emoji: '🔀',
    value: 'twisted_rightwards_arrows'
  },
  package: {
    description: 'コンパイル済みファイルやパッケージの追加/更新 | Add or update compiled files or packages',
    emoji: '📦',
    value: 'package'
  },
  alien: {
    description: '外部APIの変更に伴うコードの更新 | Update code due to external API changes',
    emoji: '👽️',
    value: 'alien'
  },
  truck: {
    description: 'リソース (例：ファイル、パス、ルート) を移動/名称変更 | Move or rename resources (e.g.: files, paths, routes)',
    emoji: '🚚',
    value: 'truck'
  },
  page_facing_up: {
    description: 'ライセンスの追加/更新 | Add or update license',
    emoji: '📄',
    value: 'page_facing_up'
  },
  boom: {
    description: '破壊的な変更の導入 | Introduce breaking changes',
    emoji: '💥',
    value: 'boom'
  },
  bento: {
    description: 'アセットの追加/更新 | Add or update assets',
    emoji: '🍱',
    value: 'bento'
  },
  wheelchair: {
    description: 'アクセシビリティ改善 | Improve accessibility',
    emoji: '♿️',
    value: 'wheelchair'
  },
  bulb: {
    description: 'ソースコード上のコメントの追加/更新 | Add or update comments in source code',
    emoji: '💡',
    value: 'bulb'
  },
  beers: {
    description: '酔った勢いでコードを書く | Write code drunkenly',
    emoji: '🍻',
    value: 'beers'
  },
  speech_balloon: {
    description: 'ドキュメンテーションを追加/更新 | Add or update text and literals',
    emoji: '💬',
    value: 'speech_balloon'
  },
  card_file_box: {
    description: 'データベース関連の変更の実行 | Perform database related changes',
    emoji: '🗃️',
    value: 'card_file_box'
  },
  loud_sound: {
    description: 'ログの追加/更新 | Add or update logs',
    emoji: '🔊',
    value: 'loud_sound'
  },
  mute: {
    description: 'ログ削除 | Remove logs',
    emoji: '🔇',
    value: 'mute'
  },
  busts_in_silhouette: {
    description: 'コントリビューター追加/更新 | Add or update contributor(s)',
    emoji: '👥',
    value: 'busts_in_silhouette'
  },
  children_crossing: {
    description: 'UX/ユーザビリティ改善 | Improve user experience/usability',
    emoji: '🚸',
    value: 'children_crossing'
  },
  building_construction: {
    description: 'アーキテクチャの変更 | Make architectural changes',
    emoji: '🏗️',
    value: 'building_construction'
  },
  iphone: {
    description: 'レスポンシブデザイン | Work on responsive design',
    emoji: '📱',
    value: 'iphone'
  },
  clown_face: {
    description: 'モックテスト | Mock things',
    emoji: '🤡',
    value: 'clown_face'
  },
  egg: {
    description: 'イースターエッグ追加 | Add or update an easter egg',
    emoji: '🥚',
    value: 'egg'
  },
  see_no_evil: {
    description: '.gitignore追加 | Add or update a .gitignore file',
    emoji: '🙈',
    value: 'see_no_evil'
  },
  camera_flash: {
    description: 'スナップショット追加/更新 | Add or update snapshots',
    emoji: '📸',
    value: 'camera_flash'
  },
  alembic: {
    description: '新機能の実験 | Perform experiments',
    emoji: '⚗️',
    value: 'alembic'
  },
  mag: {
    description: 'SEO改善 | Improve SEO',
    emoji: '🔍',
    value: 'mag'
  },
  label: {
    description: '型の追加/更新 | Add or update types',
    emoji: '🏷️',
    value: 'label'
  },
  seedling: {
    description: 'シードファイルの追加/更新 | Add or update seed files',
    emoji: '🌱',
    value: 'seedling'
  },
  triangular_flag_on_post: {
    description: 'フィーチャーフラグの追加/更新/削除 | Add, update, or remove feature flags',
    emoji: '🚩',
    value: 'triangular_flag_on_post'
  },
  goal_net: {
    description: 'エラーキャッチ | Catch errors',
    emoji: '🥅',
    value: 'goal_net'
  },
  dizzy: {
    description: 'アニメーションやトランジションの追加/更新 | Add or update animations and transitions',
    emoji: '💫',
    value: 'dizzy'
  },
  wastebasket: {
    description: 'クリーンアップが必要なコードの非推奨化 | Deprecate code that needs to be cleaned up',
    emoji: '🗑️',
    value: 'wastebasket'
  },
  passport_control: {
    description: '認証/ロール/パーミッションに関するコード | Work on code related to authorization, roles and permissions',
    emoji: '🛂',
    value: 'passport_control'
  },
  adhesive_bandage: {
    description: '重大でない問題の軽微な修正 | Simple fix for a non-critical issue',
    emoji: '🩹',
    value: 'adhesive_bandage'
  },
  monocle_face: {
    description: 'データの探索/検査 | Data exploration/inspection',
    emoji: '🧐',
    value: 'monocle_face'
  },
  coffin: {
    description: 'デッドコード削除 | Remove dead code',
    emoji: '⚰️',
    value: 'coffin'
  },
  necktie: {
    description: 'ビジネスロジックの追加/更新 | Add or update business logic',
    emoji: '👔',
    value: 'necktie'
  },
  stethoscope: {
    description: 'ヘルスチェックの追加/更新 | Add or update healthcheck',
    emoji: '🩺',
    value: 'stethoscope'
  },
  bricks: {
    description: 'インフラ関連の変更 | Infrastructure related changes',
    emoji: '🧱',
    value: 'bricks'
  },
  technologist: {
    description: 'DX改善 | Improve developer experience',
    emoji: '🧑‍💻',
    value: 'technologist'
  },
  money_with_wings: {
    description: 'スポンサーやお金に関するインフラの追加 | Add sponsorships or money related infrastructure',
    emoji: '💸',
    value: 'money_with_wings'
  },
  thread: {
    description: 'マルチスレッドや並行処理に関連するコードの追加/更新 | Add or update code related to multithreading or concurrency',
    emoji: '🧵',
    value: 'thread'
  },
  safety_vest: {
    description: 'バリデーションの追加/更新 | Add or update code related to validation',
    emoji: '🦺',
    value: 'safety_vest'
  }
};


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
