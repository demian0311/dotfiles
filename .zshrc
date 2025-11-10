bindkey -v

# Enable truecolor (24-bit) in supported terminals
if [[ "$COLORTERM" == "truecolor" ]] || [[ "$TERM" == "xterm-256color" ]]; then
    export COLORTERM=truecolor
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/opt/homebrew/bin/"
export PATH="$PATH:/opt/homebrew/bin//"
#export PATH="$PATH:~/bin/"
export PATH="$HOME/bin/:$PATH"

autoload -Uz compinit
compinit -i  # -i = ignore insecure directories
autoload -Uz compdef


HOST=$(hostname -s)
case $HOST in
   MAC-HM32XJ06N0)
      #PS1='%F{$NORD_RED}%~%f %F{$NORD_GREEN}❱%f %F{$NORD_BLUE}'
      PS1='%~ ❱ '
      eval "$(ssh-agent -s)"
      ssh-add -q ~/.ssh/id_ed25519_demian0311
      ;;
   *)
      # Fallback: Default Nord
      #PS1='%F{$NORD_RED}%~%f %F{$NORD_GREEN}❱%f %F{$NORD_BLUE}'
      PS1='%{%F{#BF616A}%}%~%{%f%} %{%F{#A3BE8C}%}❱%{%f%} %{%F{#81A1C1}%}'
      precmd() { print -Pn "%{\e[0m%}" }
    ;;
esac


# SDKMAN to manage Java
#source "$HOME/.sdkman/bin/sdkman-init.sh"
#source "$HOME/code/dotfiles/.zsh.aliases.sh"

# shell autocompletes for uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
eval "$(zoxide init zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
source ~/.zsh.aliases.sh

~/bin/banner.sh
