#!/usr/local/bin/fish

##### Custom Settings
fish_vi_mode

# git settings
git config --global user.name "Demian Neidetcher"
git config --global user.email "demian0311@gmail.com"
git config --global color.ui "auto"
git config --global push.default "current"

##### Path
set -gx PATH $PATH ~/bin 

##### Aliases
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
alias gl="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

# This is the find I always want to use when working in code directories 
alias cfind="find . -type f -not -iwholename '*.idea*' -not -iwholename '*.git*' -not -iwholename '*.gradle*' -not -iwholename '*build*'"

#alias pj='ps -ef | grep java'
#alias pt='ps -ef | grep tomcat'
#alias kj='kill -9 `jps -mv | grep jetty | cut -f1 --delimiter=" "`'
#alias kg='kill -9 `jps -mv | grep grails | cut -f1 --delimiter=" "`'

# IP addresses
alias network.ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias network.localip="ipconfig getifaddr en0"
alias network.ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

alias map="xargs -n1"

# Often useful to prefix with SUDO to see more system level network usage
alias network.ports='netstat -a -n | grep -i "LISTEN "'
alias network.connections='lsof -l -i +L -R -V'
alias network.established='lsof -l -i +L -R -V | grep ESTABLISHED'

alias serve='python -c "import SimpleHTTPServer;SimpleHTTPServer.test()"' 
alias digga='dig +nocmd "$argv" any +multiline +noall +answer;'

alias cd.r="cd ~/code/layered/router/"
alias cd.t="cd ~/code/layered/terminator/"
alias cd.h="cd ~/code/layered/heimdall/"
alias cd.a="cd ~/code/layered/asgard/"

###### Functions

function pass
   tput setaf 2
   echo -e "##### PASS #####"
   tput sgr0
   say "pass"
end

function fail
   tput setaf 1
   echo -e "##### FAIL #####"
   tput sgr0
   say "fail"
end

function g.test 
   ./gradlew test 
   if [ $status -ne 0 ]
      fail
      open ./build/reports/tests/index.html
   else
      pass
   end 
end

function g.cov 
   ./gradlew clean cobertura
   if [ $status -ne 0 ]
      fail
      open ./build/reports/tests/index.html
   else
      pass
      open ./build/reports/cobertura/index.html
   end
end

function g.check 
   ./gradlew check

   if [ $status -ne 0 ]
      fail
   else
      pass
   end
end

function g.mutest 
   ./gradlew pitest
   if [ $status -ne 0 ]
      fail
   else
      pass
      #open $(find ./build/reports/pitest -name index.html | head -n 1)
   end
end

function g.run 
   set PROJECT (basename $PWD)
   tail -f $PROJECT.log &
   echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
   ./gradlew bootRun 
end

