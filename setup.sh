#!/bin/zsh

DOT_DIR="$HOME/repositories/github.com/shu-illy/dotfiles"
GHQ_ROOT="$(git config ghq.root)"

function install_homebrew_tools {
  # --- Homebrewがインストールされているか確認する ---
  if ! command -v brew &>/dev/null; then
    echo "Homebrewが見つかりません。Homebrewをインストールします..."

    # Xcode Command Line Toolsがインストールされているか確認する
    if ! command -v xcode-select &>/dev/null; then
      echo "Xcode Command Line Toolsが見つかりません。インストールします..."
      xcode-select --install
      echo "Xcode Command Line Toolsをインストールするためにターミナルを再起動してください。"
      exit 1
    fi

    # Homebrewのインストールコマンドを実行する
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # インストールが成功したか確認する
    if [[ $? -eq 0 ]]; then
      echo "Homebrewのインストールが完了しました。"
    else
      echo "Homebrewのインストール中にエラーが発生しました。"
      exit 1
    fi
  else
    echo "Homebrewが既にインストールされています。"
  fi

  # brew bundle の標準出力が BREW_BUNDLE_IDLE_SEC 秒以上途切れたら打ち切る（0 または未設定のときは監視なし）
  if [[ -n "${BREW_BUNDLE_IDLE_SEC}" ]] && (( BREW_BUNDLE_IDLE_SEC > 0 )); then
    echo "brew bundle: 出力が ${BREW_BUNDLE_IDLE_SEC} 秒以上止まったら打ち切ります（BREW_BUNDLE_IDLE_SEC）"
    run_with_output_idle_timeout "${BREW_BUNDLE_IDLE_SEC}" brew bundle --file="$DOT_DIR/Homebrew/Brewfile" || {
      local ec=$?
      if (( ec == 124 )); then
        echo "brew bundle が出力アイドルで終了しました。ネットやリポの応答待ちの長い作業中は、BREW_BUNDLE_IDLE_SEC を大きくするか一時的に unexport して再実行してください。" >&2
      fi
      return $ec
    }
  else
    brew bundle --file="$DOT_DIR/Homebrew/Brewfile"
  fi
}

# 標準出力（stderr は stdout に合流）が idle_sec 秒以上読めなければ子を kill
function run_with_output_idle_timeout {
  local idle_sec="$1"
  shift
  if ! command -v python3 &>/dev/null; then
    echo "python3 がないため、出力アイドル監視をスキップしてそのまま実行します。"
    "$@"
    return
  fi
  python3 -c '
import os, select, sys, subprocess
idle = float(sys.argv[1])
cmd = sys.argv[2:]
p = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    bufsize=0,
    env=os.environ,
    text=True,
)
if not p.stdout:
    sys.exit(1)
try:
    while True:
        if p.poll() is not None:
            rest = p.stdout.read() or ""
            if rest:
                sys.stdout.write(rest)
                sys.stdout.flush()
            rc = p.returncode
            if rc is None:
                p.wait()
                rc = p.returncode
            sys.exit(rc if rc is not None else 1)
        r, _, _ = select.select([p.stdout], [], [], idle)
        if r:
            chunk = p.stdout.read(4096)
            if not chunk:
                break
            sys.stdout.write(chunk)
            sys.stdout.flush()
        else:
            p.kill()
            p.wait()
            print(
                "\n[timeout] 子プロセスの標準出力が %d 秒以上途切れました。"
                % int(idle),
                file=sys.stderr,
            )
            sys.exit(124)
    p.wait()
    sys.exit(p.returncode if p.returncode is not None else 0)
except KeyboardInterrupt:
    p.kill()
    p.wait()
    sys.exit(130)
' "$idle_sec" "$@"
}

function link_dotfiles {
  if [ ! -d "$HOME/.config" ]; then
    mkdir "$HOME/.config"
  fi

  # --- Sheldonの設定 ---
  if [ ! -d "$HOME/.config/sheldon" ]; then
    mkdir "$HOME/.config/sheldon"
  fi
  ln -fs "$DOT_DIR/.config/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
  sheldon lock && sheldon source

  # --- starship設定ファイルのシンボリックリンク作成 ---
  ln -fs "$DOT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

  # --- wezterm設定ファイルのシンボリックリンク作成 ---
  if [ ! -d "$HOME/.config/wezterm" ]; then
    mkdir -p "$HOME/.config/wezterm"
  fi
  for file in "$DOT_DIR/.config/wezterm"/*; do
    ln -fs "$file" "$HOME/.config/wezterm/$(basename "$file")"
  done

  # --- mise設定ファイルのシンボリックリンク作成 ---
  if [ ! -d "$HOME/.mise" ]; then
    mkdir -p "$HOME/.mise"
  fi
  ln -fs "$DOT_DIR/.config/mise/config.toml" "$HOME/.config/.mise/config.toml"

  # --- VSCode / Cursorの設定ファイルのシンボリックリンク作成 ---
  CODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User/"
  CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User/"
  editor_config_dirs=("$CODE_CONFIG_DIR" "$CURSOR_CONFIG_DIR")

  for config_dir in "${editor_config_dirs[@]}"; do
    if [ ! -d $config_dir ]; then
      mkdir -p $config_dir
    fi
    for file in "$DOT_DIR/.config/vscode"/*; do
      ln -fs "$file" "$config_dir/$(basename "$file")"
    done
  done

  # --- dotfileのリンク作成 ---
  if [ ! -d "$HOME/.dotbackup" ]; then
    mkdir "$HOME/.dotbackup"
  fi

  # --- .gitconfig, .zshrcのリンク作成 ---
  DOT_FILES=(.zshrc .gitconfig)
  for file in ${DOT_FILES[@]}; do
    if [ -f "$HOME/$file" ]; then
      mv "$HOME/$file" "$HOME/.dotbackup/$file"
    fi
    ln -fs $DOT_DIR/$file $HOME/$file
  done

  # --- .config/ai/.claude/設定ファイルのリンク作成 ---
  if [ ! -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude"
  fi
  ln -fs "$DOT_DIR/.config/ai/.claude/settings.json" "$HOME/.claude/settings.json"
  ln -fs "$DOT_DIR/.config/ai/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  ln -fs "$DOT_DIR/.config/ai/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  # 既存のファイルやディレクトリを削除してからシンボリックリンクを作成
  if [ -e "$HOME/.claude/commands" ]; then
    rm -rf "$HOME/.claude/commands"
  fi
  ln -fs "$DOT_DIR/.config/ai/.claude/commands" "$HOME/.claude/commands"

  if [ -e "$HOME/.claude/skills" ]; then
    rm -rf "$HOME/.claude/skills"
  fi
  ln -fs "$DOT_DIR/.config/ai/.claude/skills" "$HOME/.claude/skills"

  # --- .config/ai/.claude/agents/設定ファイルのリンク作成 ---
  if [ -e "$HOME/.claude/agents" ]; then
    rm -rf "$HOME/.claude/agents"
  fi
  ln -fs "$DOT_DIR/.config/ai/.claude/agents" "$HOME/.claude/agents"

  # --- .config/ai/.codex/設定ファイルのリンク作成 ---
  if [ ! -d "$HOME/.codex" ]; then
    mkdir -p "$HOME/.codex"
  fi
  ln -fs "$DOT_DIR/.config/ai/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

  # --- .config/ai/.gemini/設定ファイルのリンク作成 ---
  if [ ! -d "$HOME/.gemini" ]; then
    mkdir -p "$HOME/.gemini"
  fi
  ln -fs "$DOT_DIR/.config/ai/.gemini/settings.json" "$HOME/.gemini/settings.json"

  # git-cz用設定ファイルのリンク作成
  eval ln -fs "$DOT_DIR/git/changelog.config.js" "$HOME/changelog.config.js"

}

echo "dotfiles for macOS

SETUP MENU:
  [a] Execute all
  [i] Install tools
  [l] Link dotfiles
"
read -r result
echo ""

if [[ "$result" == *"a"* ]] || [[ "$result" == *"i"* ]]; then
  install_homebrew_tools
fi

if [[ "$result" == *"a"* ]] || [[ "$result" == *"l"* ]]; then
  link_dotfiles
fi

source ~/.zshrc

echo "[ Finished! ]"
