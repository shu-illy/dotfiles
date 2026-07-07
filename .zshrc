eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(sheldon source)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/shilly/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/shilly/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/shilly/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/shilly/google-cloud-sdk/completion.zsh.inc'; fi
