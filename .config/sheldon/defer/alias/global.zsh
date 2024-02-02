# === エイリアス Docker関連 ===
alias dc='docker-compose'
alias d='docker'
alias da='docker attach'
alias dcb='dcoker-compose build'
alias dcu='docker-compose up'
# 停止コンテナ一括削除
alias drmc='docker rm `docker ps -f "status=exited" -q`'
# 未使用イメージ一括削除
alias drmi='docker image prune'
# 未使用ボリューム一括削除
alias drmv='docker volume prune'
alias dcur='docker-compose up rails'
# railsコンテナが起動している場合のみ使用可
alias dcsh='docker-compose exec rails bash'
# ==========================


# === エイリアス git関連 ===
alias g="git"
alias gpso="git push origin"
alias gps='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin "$current_branch"'
alias gpsf='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin -f "$current_branch"'
alias gpl="git pull origin"
alias gplr="git pull --rebase --autostash origin"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gs="git switch"
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
alias gcf="git branch -a | fzf | xargs git checkout" # fzfで一覧表示したbranchを選択してcheckout
# ========================

# === エイリアス Rails関連 ===
alias be="bundle exec"
alias bi="bundle install"
alias rs="bundle exec rspec"
alias rc="bundle exec rubocop"
alias rcp="bundle exec rubocop --parallel"
alias rctd="bundle exec rubocop --auto-gen-config"
# ========================

# エイリアス NeoVim関連
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"

# エイリアス RubyMine関係
alias rbm="rubymine"

# git管理下のテキストを置換
# greplace hoge fuga
function greplace() {
  git grep -l $1 $3 | xargs sed -i -e "s/$1/$2/g"
  find . -name '*-e' | xargs rm
}
