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

  brew bundle --file="$DOT_DIR/Homebrew/Brewfile"
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

  # --- starship設定ファイルのシンボリックリンク作成 ---
  ln -fs "$DOT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

  # --- wezterm設定ファイルのシンボリックリンク作成 ---
  if [ ! -d "$HOME/.config/wezterm" ]; then
    mkdir -p "$HOME/.config/wezterm"
  fi
  for file in "$DOT_DIR/.config/wezterm"/*; do
    ln -fs "$file" "$HOME/.config/wezterm/$(basename "$file")"
  done

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
