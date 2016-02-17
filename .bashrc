#Demian Neidetcher

platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   echo 'loading config for Linux OS'
   alias ls='ls -hlt --color'
   export PATH=$PATH:/usr/local/bin/
elif [[ "$unamestr" == 'Darwin' ]]; then
   echo -n ''

   #alias gvim='/Applications/MacVim.app/Contents/MacOS/Vim -g'

   alias md5sum="md5"

   export PATH="/usr/local/bin:$PATH"

   export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
   export JAVA_HOME=$JRE_HOME
   export JDK_HOME=$JRE_HOME
   export PATH=$JAVA_HOME/bin:$PATH
   

   #VIM_APP_DIR=/usr/local/Cellar/macvim/7.3-61/MacVim.app
   VIM_APP_DIR=/usr/local/Cellar/vim/7.4.712
   export PATH=$VIM_APP_DIR/Contents/MacOS:$PATH

   # enable programmable completion features (you don't need to enable
   # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
   # sources /etc/bash.bashrc).
   if [ -f /etc/bash_completion ]; then
       . /etc/bash_completion
   fi

   export OPT=~/opt
   # Java Options, Groovy uses this too
   #export JAVA_OPTS="-Xmx4096m -Xms4096m"

   export SCALA_HOME=$OPT/scala
   export PATH=$SCALA_HOME/bin:$PATH

   export GROOVY_HOME=$OPT/groovy
   export PATH=$GROOVY_HOME/bin:$PATH

   export MAX_HEAP='2048m'
   export MAX_PERM='512m'
   export GRADLE_HOME=$OPT/gradle
   export PATH=$GRADLE_HOME/bin:$PATH
   export EDITOR=vim
   export PATH=~/bin:$PATH
fi

set -o vi

#PS1="\u@\h \w>"

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

if [ -f ~/.git.tools ]; then
    . ~/.git.tools
fi

# git settings
git config --global user.name "Demian Neidetcher"
git config --global user.email "demian0311@gmail.com"
git config --global color.ui "auto"
git config --global push.default "current"

# http://b.sricola.com/post/16174981053/bash-autocomplete-for-ssh
complete -W "$(echo $(grep '^ssh ' ~/.bash_history | sort -u | sed 's/^ssh //'))" ssh
complete -W "$(echo $(grep "Host " ~/.ssh/config | awk '{print $2}' | tr "\n" " "))" ssh

export PATH="~/code/twc/potion/bin:$PATH"
alias jump="~/code/twc/potion/bin/jump"
#. /Users/demian/code/twc/devops/bin/jump 

if [ -f ~/code/twc/devops/scripts/liger_aliases.sh ]; then
   .  ~/code/twc/devops/scripts/liger_aliases.sh 
fi

export TWC_USERNAME=dneidetcher

export DOTFILES=~/code/dotfiles
source $DOTFILES/.bash_aliases.sh
source $DOTFILES/.bash_functions.sh
source $DOTFILES/.bash_prompt.sh
export PATH="$DOTFILES/bin:$PATH"

j8
