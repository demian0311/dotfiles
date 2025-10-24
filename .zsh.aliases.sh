alias l='eza -lha --color-scale=size --group-directories-first --git --git-repos'
alias cat='bat -p --theme Coldark-Dark'
alias v='vim'
alias vi='vim'
alias c='cd'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

export FZF_DEFAULT_OPTS="--height=30% --layout reverse --style full --preview 'bat --color always -p --theme Coldark-Dark {}'"
# this gets you vim ** and cd **
source <(fzf --zsh)

#alias g='git'
#alias gd='git diff --color-words'
#alias gs='git status --short'
#alias gl="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

# This is the find I always want to use when working in code directories 
alias cfind="find . -type f -not -iwholename '*.idea*' -not -iwholename '*.git*' -not -iwholename '*.gradle*' -not -iwholename '*build*'"

# IP addresses
alias network.ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias network.localip="ipconfig getifaddr en0"
#alias network.ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Often useful to prefix with SUDO to see more system level network usage
alias network.ports='netstat -a -n | grep -i "LISTEN "'
alias network.connections='lsof -l -i +L -R -V'
alias network.established='lsof -l -i +L -R -V | grep ESTABLISHED'

alias serve='python -c "import SimpleHTTPServer;SimpleHTTPServer.test()"' 
