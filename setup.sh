#!/bin/zsh

DOT_DIR="$HOME/dotfiles"


# --- Homebrewがインストールされているか確認する ---
if ! command -v brew &> /dev/null; then
    echo "Homebrewが見つかりません。Homebrewをインストールします..."

    # Xcode Command Line Toolsがインストールされているか確認する
    if ! command -v xcode-select &> /dev/null; then
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


# --- Sheldonの導入・設定 ---
if ! command -v sheldon &> /dev/null; then
    echo "Sheldonをインストールします..."
    brew install sheldon
fi

if [ ! -d "$HOME/.config" ]; then
    mkdir "$HOME/.config"
fi

if [ ! -d "$HOME/.config/sheldon" ]; then
    mkdir "$HOME/.config/sheldon"
fi

if [ -f "$HOME/.config/sheldon/plugins.toml" ]; then
    rm "$HOME/.config/sheldon/plugins.toml"
fi
command ln -s "$DOT_DIR/.config/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"


# --- dotfileのリンク作成 ---
if [ ! -d "$HOME/.dotbackup" ]; then
    mkdir "$HOME/.dotbackup"
fi

DOT_FILES=(.zshrc .gitconfig)
for file in ${DOT_FILES[@]}
do
    if [ -f "$HOME/$file" ]; then
        mv "$HOME/$file" ".dotbackup/$file"
    fi
    ln -s $HOME/dotfiles/$file $HOME/$file
done