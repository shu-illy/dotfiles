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
alias gda='git branch | grep -v -E "^\*|main|develop" | xargs -r git branch -D' # 現在のブランチ、mainブランチ、developブランチ以外を全削除
alias gw='git worktree list'

# git worktree addのラッパー関数
# 使い方: gwa <directory_name>
# 例: gwa feature-auth → ../ に feature-auth ディレクトリを作成し、iri/feature-auth ブランチで worktree を追加
function gwa() {
  local name=$1

  if [ -z "$name" ]; then
    echo "Usage: gwa <directory_name>"
    return 1
  fi

  local repo_name=$(basename $(git rev-parse --show-toplevel))
  local branch_name="iri/${name}"
  local worktree_path="../wt_${repo_name}_${name}"
  local original_dir=$(pwd)

  git worktree add "$worktree_path" -b "$branch_name"
  
  # .envrc と .env ファイルがあればコピー
  if [ -f "$original_dir/.envrc" ]; then
    cp "$original_dir/.envrc" "$worktree_path/.envrc"
    echo "Copied .envrc to worktree"
  fi
  
  if [ -f "$original_dir/.env" ]; then
    cp "$original_dir/.env" "$worktree_path/.env"
    echo "Copied .env to worktree"
  fi

  if [ -f "$original_dir/.env.development.local" ]; then
    cp "$original_dir/.env.development.local" "$worktree_path/.env.development.local"
    echo "Copied .env.development.local to worktree"
  fi
  
  cd "$worktree_path"
  
  # .envrcがコピーされた場合はdirenv allowを実行
  if [ -f ".envrc" ]; then
    direnv allow
    echo "Executed 'direnv allow' for .envrc"
  fi
  yarn install
  bundle install
}

# git worktree removeのラッパー関数
# 使い方:
#   gwr                    fzf（fzfが無ければ select + PS3）で worktree を選択して削除
#   gwr <directory_name>   ../wt_{repo}_{name} を削除し、対応する iri/{name} ブランチも削除（従来互換）
#   gwr <path>             フルパス/相対パスで指定した worktree を削除
# 例: gwr feature-auth → ../wt_{repo}_feature-auth を削除し、iri/feature-auth ブランチも削除
#
# 備考:
#   - 未コミットの変更等で git worktree remove が失敗しても -f による強制削除は絶対に行わない
#   - 削除対象に対応するブランチは iri/<name> 規約に依存せず git worktree list --porcelain から特定する
#     (fzf選択・フルパス指定でも同様に動作する)
#   - main/master/develop、detached HEAD、bare worktree、branch特定不能な場合はブランチ削除をスキップする
function gwr() {
  local arg=$1

  local current_toplevel
  current_toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repository"; return 1; }

  # git worktree list --porcelain を "path<TAB>branch" の1行形式に整形しておく
  # (remove の前に取得すること。remove後はここに情報が残らずbranch_nameが空になってしまう)
  local entries
  entries=$(git worktree list --porcelain 2>/dev/null | awk '
    /^worktree /{ path=substr($0, 10); branch="" }
    /^branch /  { branch=substr($0, 8); sub("^refs/heads/", "", branch) }
    /^$/        { if (path != "") print path "\t" branch; path="" }
  ')

  local worktree_path

  if [ -z "$arg" ]; then
    # 引数なし: fzf（無ければ select）で選択。現在の worktree は一覧から除外
    local list
    list=$(echo "$entries" | awk -F'\t' -v cur="$current_toplevel" '$1 != cur')

    if [ -z "$list" ]; then
      echo "削除可能な worktree がありません"
      return 1
    fi

    local selected
    if command -v fzf > /dev/null 2>&1; then
      selected=$(echo "$list" | fzf | awk -F'\t' '{print $1}')
    else
      local -a paths
      paths=(${(f)"$(echo "$list" | awk -F'\t' '{print $1}')"})
      PS3="削除する worktree を選択してください: "
      # 注意: ループ変数名は "path" にしないこと（zshの特殊変数 $PATH とタイされており破壊される）
      select choice in "${paths[@]}"; do
        [[ -n $choice ]] && selected=$choice && break
      done
    fi

    if [ -z "$selected" ]; then
      echo "worktree が選択されませんでした"
      return 1
    fi
    worktree_path=$selected
  elif [[ "$arg" == */* || -d "$arg" ]]; then
    # フルパス（または相対パス）指定
    worktree_path=${arg:A}
  else
    # 従来のディレクトリ名規約（iri/<name>, ../wt_<repo>_<name>）
    local repo_name=$(basename "$current_toplevel")
    worktree_path="../wt_${repo_name}_${arg}"
  fi

  worktree_path=${worktree_path:A}

  # 削除対象のworktreeに対応するブランチを remove の前に特定しておく
  local branch_name
  branch_name=$(echo "$entries" | awk -F'\t' -v target="$worktree_path" '$1 == target { print $2 }')

  # worktree を削除（未コミットの変更等で失敗しても -f による強制削除は行わない）
  if ! git worktree remove "$worktree_path"; then
    echo "worktree の削除に失敗しました: $worktree_path"
    echo "未コミットの変更が残っている可能性があります。内容を確認のうえ手動で対応してください。"
    return 1
  fi

  # ブランチの削除（保護ブランチ・detached/bare・特定不能な場合はスキップ）
  if [ -z "$branch_name" ]; then
    echo "削除対象のブランチを特定できなかったため、ブランチ削除をスキップしました"
    return 0
  fi

  case "$branch_name" in
    main|master|develop)
      echo "保護対象のブランチ (${branch_name}) のため削除をスキップしました"
      return 0
      ;;
  esac

  git branch -D "$branch_name"
}

# git worktree を選択して cd するラッパー関数
function gwcd() {
  local worktrees
  worktrees=$(git worktree list 2>/dev/null) || { echo "Not a git repository"; return 1; }

  local selected
  if command -v fzf > /dev/null 2>&1; then
    selected=$(echo "$worktrees" | fzf | awk '{print $1}')
  else
    local -a paths
    paths=(${(f)"$(echo "$worktrees" | awk '{print $1}')"})
    PS3="worktree を選択してください: "
    # 注意: ループ変数名は "path" にしないこと（zshの特殊変数 $PATH とタイされており破壊される）
    select choice in "${paths[@]}"; do
      [[ -n $choice ]] && selected=$choice && break
    done
  fi

  [[ -n $selected ]] && cd "$selected"
}

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
