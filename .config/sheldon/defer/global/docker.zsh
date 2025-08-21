# エイリアス Docker関連

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