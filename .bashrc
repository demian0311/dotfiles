# Demian Neidetcher

#export GREP_OPTIONS='--ignore-case --color --silent'
#export GREP_OPTIONS='--color'

platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   echo 'loading config for Linux OS'
   alias ls='ls -hlt --color'
   export LOCAL_PUB=~/UNDEFINED

   #running on prod servers
   export PATH=$PATH:/usr/local/bin/

elif [[ "$unamestr" == 'Darwin' ]]; then
   echo '***********************************************'
   echo '* LOCAL MAC CONFIG                            *'
   echo '***********************************************'

   # TWC related
   alias xp='cd ~/code/tw/cross-platform; git pull'

   # SETUP THE NEW SBT
   #alias sbt=~/opt/sbt/bin/sbt

   # my brew stuff is all messed up, not symlinking
   alias gpg=/usr/local/Cellar/gnupg/1.4.11/bin/gpg

   #alias .gmd='grails -Dgrails.env=mockdev -Ddisable.auto.recompile=false run-app'

   #alias grails1='export GRAILS_HOME=$GRAILS1_HOME && $GRAILS1_HOME/bin/grails'
   #alias grails2='export GRAILS_HOME=$GRAILS2_HOME && $GRAILS2_HOME/bin/grails'
   #alias grails='export GRAILS_HOME=~/opt/.grails-2.2.4 && ~/opt/.grails-2.2.1/bin/grails'

   alias grails221='export GRAILS_HOME=~/opt/.grails-2.2.1 && ~/opt/.grails-2.2.1/bin/grails'
   alias grails230='export GRAILS_HOME=~/opt/.grails-2.3.0 && ~/opt/.grails-2.3.0/bin/grails'
   alias grails231='export GRAILS_HOME=~/opt/.grails-2.3.1 && ~/opt/.grails-2.3.1/bin/grails'
   alias grails232='export GRAILS_HOME=~/opt/.grails-2.3.2 && ~/opt/.grails-2.3.2/bin/grails'

   alias vpn.restart='sudo /System/Library/StartupItems/CiscoVPN/CiscoVPN restart'

   alias gvim='/Applications/MacVim.app/Contents/MacOS/Vim -g'
   # some aliases to make mac better
   alias md5sum="md5"
   #alias wget="curl -O"

   export PATH="/usr/local/bin:$PATH"

   #export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
   #export JRE_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home/
   export JRE_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home/
   #export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_25.jdk/Contents/Home
   export JAVA_HOME=$JRE_HOME
   export JDK_HOME=$JRE_HOME
   export PATH=$JAVA_HOME/bin:$PATH

   export LOCAL_PUB=/Users/demian/Sites

   VIM_APP_DIR=/usr/local/Cellar/macvim/7.3-61/MacVim.app
   export PATH=$VIM_APP_DIR/Contents/MacOS:$PATH

   # set up paths
   export OPT=~/opt

   # enable programmable completion features (you don't need to enable
   # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
   # sources /etc/bash.bashrc).
   if [ -f /etc/bash_completion ]; then
       . /etc/bash_completion
   fi

   # Java Options, Groovy uses this too
   #export JAVA_OPTS="-Xmx2048m -Xms2048m"
   export JAVA_OPTS="-Xmx4096m -Xms4096m"

   export SCALA_HOME=$OPT/scala
   export PATH=$SCALA_HOME/bin:$PATH

   export GROOVY_HOME=$OPT/groovy
   export PATH=$GROOVY_HOME/bin:$PATH

   export PLAY_HOME=$OPT/play
   export PATH=$PLAY_HOME:$PATH

   export CLASSPATH=.
   export CLASSPATH=$CLASSPATH:$SCALA_HOME/lib/

   export GRAILS_HOME=$OPT/grails
   export PATH=$GRAILS_HOME/bin:$PATH

   export CXF_HOME=$OPT/cxf
   export PATH=$CXF_HOME/bin:$PATH

   export RUBY_HOME=/usr/local/Cellar/ruby/1.9.2-p136
   export PATH=$RUBY_HOME/bin:$PATH

   export MAX_HEAP='2048m'
   export MAX_PERM='512m'
   export GRADLE_HOME=$OPT/gradle
   export PATH=$GRADLE_HOME/bin:$PATH

   #export M3_HOME=$OPT/maven
   #export M2_HOME=$M3_HOME
   #export PATH=$M3_HOME/bin:$PATH

   # defined just like eclipse
   #export M2_REPO=~/.m2/repository
   export SVN_EDITOR=vim
   export EDITOR=vim

   export PATH=~/bin:$PATH

   ##export MAVEN_OPTS="-Xmx2048m -Xms2048m -Dsurefire.useFile=false"

   #alias jekyll='/usr/local/Cellar/ruby/2.0.0-p0/bin/jekyll'

fi

PS1="\u@\h \w>"

[ -z "$PS1" ] && return # If not running interactively, don't do anything
# vi mode editing on the commandline
set -o vi 

# bash history
export HISTSIZE=5000
export HISTCONTROL=ignoredups
export HISTCONTROL=ignoreboth
export HISTIGNORE="&:ls:[bf]g:exit"
shopt -s histappend
shopt -s cmdhist
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)" # make less more friendly for non-text input files, see lesspipe(1)

if [ -f ~/.aliases.sh ]; then
    . ~/.aliases.sh
fi

# git settings
git config --global user.name "Demian Neidetcher"
git config --global user.email "demian0311@gmail.com"
git config --global color.ui "auto"
git config --global push.default "current"

# http://b.sricola.com/post/16174981053/bash-autocomplete-for-ssh
complete -W "$(echo $(grep '^ssh ' .bash_history | sort -u | sed 's/^ssh //'))" ssh
complete -W "$(echo $(grep "Host " ~/.ssh/config | awk '{print $2}' | tr "\n" " "))" ssh

export PATH="~/code/twc/potion/bin:$PATH"
alias jump="~/code/twc/potion/bin/jump"
#. /Users/demian/code/twc/devops/bin/jump 

if [ -f ~/code/twc/devops/scripts/liger_aliases.sh ]; then
   .  ~/code/twc/devops/scripts/liger_aliases.sh 
fi

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/Users/demian/.gvm/bin/gvm-init.sh" ]] && source "/Users/demian/.gvm/bin/gvm-init.sh"
