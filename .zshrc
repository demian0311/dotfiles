bindkey -v
#export= PS1='%F{#BF616A}%~%f %F{#81A1C1}❯%f '
#export= PS1='%F{#BF616A}%~%f %F{#A3BE8C}»%f '
export= PS1='%F{#BF616A}%~%f %F{#A3BE8C}❱%f '
setopt prompt_subst
zle_highlight=(default:fg=#81A1C1)

# SDKMAN to manage Java
source "$HOME/.sdkman/bin/sdkman-init.sh"
source "$HOME/code/dotfiles/.zsh.aliases.sh"

# shell autocompletes for uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
eval "$(zoxide init zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/demian/.lmstudio/bin"
# End of LM Studio CLI section
#
~/bin/banner.sh

