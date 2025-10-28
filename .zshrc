bindkey -v
export= PS1='%F{#BF616A}%~%f %F{#81A1C1}❯%f '

# SDKMAN to manage Java
source "$HOME/.sdkman/bin/sdkman-init.sh"
source "$HOME/code/dotfiles/.zsh.aliases.sh"

# shell autocompletes for uv
echo 'eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc
echo 'eval "$(uvx --generate-shell-completion zsh)"' >> ~/.zshrc
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
