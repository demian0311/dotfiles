bindkey -v
#export= PS1='%F{#BF616A}%~%f %F{#81A1C1}❯%f '
export= PS1='%F{#BF616A}%~%f %F{#A3BE8C}»%f '
setopt prompt_subst
zle_highlight=(default:fg=#81A1C1)

# SDKMAN to manage Java
source "$HOME/.sdkman/bin/sdkman-init.sh"
source "$HOME/code/dotfiles/.zsh.aliases.sh"

# shell autocompletes for uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
