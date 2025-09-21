alias src='source ~/.zshrc'

# ==========================


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
alias cu="cursor"
alias xcc='rm -rf ~/Library/Developer/Xcode/DerivedData'

# エイリアス yarn関連
alias y="yarn"
alias yi="yarn install"

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

# GhostScriptでPDFを圧縮
function pdfmin()
{
  local cnt=0
  for i in $@; do
    gs -sDEVICE=pdfwrite \
      -dCompatibilityLevel=1.4 \
      -dPDFSETTINGS=/ebook \
      -dNOPAUSE -dQUIET -dBATCH \
      -sOutputFile=${i%%.*}.min.pdf ${i} &
    (( (cnt += 1) % 4 == 0 )) && wait
  done
  wait && return 0
}
