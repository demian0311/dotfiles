#!/usr/local/bin/fish

# ln -s ~/code/dotfiles/config/fish/config.fish ~/.config/fish/
# ln -s ~/code/dotfiles/config/fish/functions ~/.config/fish/

##### Custom Fish Settings
fish_vi_mode


##### Environment Specific
switch (hostname)
case "kabar.local"
   set -x MULE_HOME "/Users/demian/opt/mule-enterprise-standalone-3.7.2"
   alias cd.i="cd ~/code/twc/mule-services/ivr/" 
   alias cd.cs="cd ~/code/twc/cim-service/" 
   alias cd.cu="cd ~/code/twc/cim-ui/" 
case '*'
   alias cd.r="cd ~/code/layered/router/"
   alias cd.t="cd ~/code/layered/terminator/"
   alias cd.h="cd ~/code/layered/heimdall/"
   alias cd.a="cd ~/code/layered/asgard/"
end

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
alias map="xargs -n1"

# Often useful to prefix with SUDO to see more system level network usage
alias net.ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias net.localip="ipconfig getifaddr en0"
alias net.ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias net.ports='netstat -a -n | grep -i "LISTEN "'
alias net.connections='lsof -l -i +L -R -V'
alias net.established='lsof -l -i +L -R -V | grep ESTABLISHED'
alias net.dns='dig +nocmd "$argv" any +multiline +noall +answer;'

alias serve='python -c "import SimpleHTTPServer;SimpleHTTPServer.test()"' 

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
