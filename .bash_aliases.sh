alias ls='ls -G -p'
alias ll='ls -Ghalt'
alias l='ls -Ghlt'
alias v='vim'
alias vi='vim'
alias c='cd'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias g='git'
alias gd='git diff --color-words'
alias gs='git status --short'
#alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias gl="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

#alias pj='ps -ef | grep java'
#alias pt='ps -ef | grep tomcat'
#alias kj='kill -9 `jps -mv | grep jetty | cut -f1 --delimiter=" "`'
#alias kg='kill -9 `jps -mv | grep grails | cut -f1 --delimiter=" "`'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

alias map="xargs -n1"

# Often useful to prefix with SUDO to see more system level network usage
alias network.ports='netstat -a -n | grep -i "LISTEN "'
alias network.connections='lsof -l -i +L -R -V'
alias network.established='lsof -l -i +L -R -V | grep ESTABLISHED'

alias serve='python -c "import SimpleHTTPServer;SimpleHTTPServer.test()"' 

alias gCoverage='./grailsw test-app -unit -coverage -xml --non-interactive --plain-output; open ./target/test-reports/cobertura/index.html'