# Vi editing mode for bash, sourced from ~/.bashrc after Omarchy's rc.
# Omarchy's inputrc binds into the emacs keymap, so its keys are re-bound here for vi-insert.
set -o vi
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'   # beam cursor in insert mode
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'   # block cursor in command mode
bind 'set keyseq-timeout 50'                 # Esc switches modes without a lag
bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-insert 'TAB: menu-complete'
bind -m vi-insert '"\e[Z": menu-complete-backward'
bind -m vi-insert '"\C-l": clear-screen'
bind -m vi-command '"\C-l": clear-screen'
