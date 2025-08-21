# エイリアス git関連

alias g="git"
alias gpso="git push origin"
alias gps='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin "$current_branch"'
alias gpsf='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin --force-with-lease --force-if-includes "$current_branch"'
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
alias gsp='git switch `git branch | fzf | sed -e "s/*//g"`'
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

# git管理下のテキストを置換
# greplace hoge fuga
function greplace() {
  git grep -l $1 $3 | xargs sed -i -e "s/$1/$2/g"
  find . -name '*-e' | xargs rm
}

# ghqでリポジトリ一覧を表示
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
