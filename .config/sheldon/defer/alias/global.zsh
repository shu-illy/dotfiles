alias src='source ~/.zshrc'

# === エイリアス Docker関連 ===
alias dc='docker compose'
alias d='docker'
alias da='docker attach'
alias dcb='dcoker compose build'
alias dcu='docker compose up'
# 停止コンテナ一括削除
alias drmc='docker rm `docker ps -f "status=exited" -q`'
# 未使用イメージ一括削除
alias drmi='docker image prune'
# 未使用ボリューム一括削除
alias drmv='docker volume prune'
alias dcur='docker compose up rails'
# railsコンテナが起動している場合のみ使用可
alias dcsh='docker compose exec rails bash'
# ==========================

# === エイリアス git関連 ===
alias g="git"
alias gpso="git push origin"
alias gps='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin "$current_branch"'
alias gpsf='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin -f "$current_branch"'
alias gpl="git pull origin"
alias gplr="git pull --rebase --autostash origin"
alias gss="git switch"
alias gsc="git switch -c"
alias gst="git stash"
alias gb="git branch"
alias gd="git branch -d"
alias gD="git branch -D"
alias gro="git rebase origin"
alias gcp="git cherry-pick"
alias glo="git log --oneline"
alias gbcp="git branch --show-current | pbcopy" # 現在のブランチ名コピー
alias gg="git grep"
alias gr="greplace"
alias gsf="git branch | fzf | xargs git switch" # fzfで一覧表示したbranchを選択してcheckout
alias gsp='git switch `git branch | peco | sed -e "s/*//g"`'
alias gca='git commit --amend'
alias lg='lazygit'
alias gpmf='git push origin main'
function gpm() {
  # ホワイトリストに含めたいリポジトリ名（リモートURLの一部やディレクトリ名など）を配列で定義
  local whitelist=("shu-illy/dotfiles")
  # 現在のリポジトリのリモートURLを取得
  local remote_url=$(git config --get remote.origin.url)
  # フラグ
  local is_whitelisted=false

  for repo in "${whitelist[@]}"; do
    if [[ "$remote_url" == *"$repo"* ]]; then
      is_whitelisted=true
      break
    fi
  done

  if $is_whitelisted; then
    git push origin main
  else
    echo "このリポジトリはホワイトリストに含まれていません"
  fi
}

# ========================

# === エイリアス Rails関連 ===
alias be="bundle exec"
alias bi="bundle install"
alias rs="bundle exec rspec"
alias rc="bundle exec rubocop --config .rubocop.yml"
alias rcp="bundle exec rubocop --parallel"
alias rctd="bundle exec rubocop --auto-gen-config"
# ========================

# エイリアス エディタ関連
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"
alias rbm="rubymine"
alias cu="cursor"
alias xcc='rm -rf ~/Library/Developer/Xcode/DerivedData'

# エイリアス yarn関連
alias y="yarn"
alias yi="yarn install"

# git管理下のテキストを置換
# greplace hoge fuga
function greplace() {
  git grep -l $1 $3 | xargs sed -i -e "s/$1/$2/g"
  find . -name '*-e' | xargs rm
}

# colordiff
# diffコマンドで差分がある場合、終了ステータスが0以外になるため、|| trueをつけている
function df() {
  colordiff "$@" || true
}

# bun completions
[ -s "/Users/shuheiiriyama/.bun/_bun" ] && source "/Users/shuheiiriyama/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ghq
function r() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    cd $(ghq root)/$src
  fi
}
# 新規リポジトリ作成してghq管理下に置く（引数でリポジトリ名指定）
function ghq-new() {
    local REPONAME=$1

    if [ -z "$REPONAME" ]; then
        echo 'Repository name must be specified.'
        return
    fi

    local TMPDIR=/tmp/ghq_new
    local TMPREPODIR=$TMPDIR/$REPONAME

    mkdir -p $TMPREPODIR
    cd $TMPREPODIR

    git init
    gh repo create $REPONAME --public --source=. --remote=origin

    local REPOURL=$(git remote get-url origin)
    local REPOPATH=$(echo $REPOURL | sed -e 's/^https:\/\///' -e 's/^git@//' -e 's/\.git$//' -e 's/github.com:/github.com\//')
    local USER_REPO_NAME=$(echo $REPOPATH | sed -e 's/^github\.com\///')

    ghq get $USER_REPO_NAME

    cd $(ghq root)/$REPOPATH

    rm -rf $TMPREPODIR
}



# 通知音
alias beep='afplay /System/Library/Sounds/Ping.aiff'

# Xcode関連
alias xclean='rm -rf ~/Library/Developer/Xcode/DerivedData' # 中間生成ファイル削除

# ^rでコマンド履歴
function fzf-select-history() {
    BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history
