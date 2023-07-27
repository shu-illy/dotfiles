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
# ==========================


# === エイリアス git関連 ===
alias g="git"
alias gps="git push origin"
alias gpsc='current_branch=$(git rev-parse --abbrev-ref HEAD); [ "$current_branch" != "develop" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "develop" ] && git push origin "$current_branch"'
alias gpl="git pull origin"
alias gplr="git pull --rebase --autostash origin"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gst="git stash"
alias gb="git branch"
alias gd="git branch -d"
alias gD="git branch -D"
alias gro="git rebase origin"
alias gcp="git cherry-pick"
alias glo="git log --oneline"
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