#!/bin/sh

mkdir -p ~/.vim/backup

## Setup symlinks to dotfiles 
function linkFile(){
	ln -s ~/code/dotfiles/$1 ~/$1 && echo "linked $1" 
}

#linkFile ".vim/syntax"
ln -s ~/code/dotfiles/.vim/syntax ~/.vim/ && echo "linked .vim/syntax" 
ln -s ~/code/dotfiles/bin/ ~/bin/ && echo "linked bin" 
linkFile ".bashrc"
linkFile ".vimrc"
linkFile ".aliases.sh"
linkFile ".gitconfig"

## Setup lots of software

function install(){
	brew list | grep --quiet $1 || ( brew install $1 && echo "$1 installed"   )
}

install "ruby"
install "libyaml"		
install "tree"
install "htop"
install "autoconf"	
install "scrypt"
install "htop-osx"	
install "nmap"		
install "pkg-config"	
install "ruby"
install "automake"	
install "libtool"		
install "maven"		
install "openssl"		
install "readline"	
install "tree"
install "icu4c"

## Stuff that needs gems
# gems in general aren't working for me
function gemInstall(){
   gem list | grep --quiet "$1 (" || ( echo "installing $1, provide password" &&  sudo gem install $1  && echo "$1 installed" )
}

gemInstall "gollum"
gemInstall "jekyll"

# I had to symlink it myself
#ln -s /usr/local/lib/ruby/gems/2.1.0/gems/gollum-2.6.0/bin/gollum /usr/local/bin/gollum
#ln -s /usr/local/lib/ruby/gems/2.1.0/gems/jekyll-1.4.3/bin/jekyll /usr/local/bin/jekyll

#gem list | grep --quiet "gollum (" 	|| ( echo "installing gollum, please provide password if asked." &&  sudo gem install gollum  && echo "gollum installed" )
#echo "gems"


## Work repos

function twcGitRepo(){
   [ -d ~/code/twc/$1 ] || git clone git@github.webapps.rr.com:liger/$1 ~/code/twc/$1;
}

twcGitRepo "soap"
twcGitRepo "cst"
twcGitRepo "care-portal-infra"
twcGitRepo "payment-gateway"
twcGitRepo "online-bill-pay"

function githubGitRepo(){
   [ -d ~/code/$1 ] || git clone git@github.com:demian0311/$1 ~/code/$1;
}

githubGitRepo "javafunctional"
githubGitRepo "demian0311.github.com"
githubGitRepo "hystrix-circuit-breaker"
githubGitRepo "nextgen"

[ -d ~/code/bash-it ] || git clone https://github.com/revans/bash-it.git ~/code/bash-it;

function bitbucketGitRepo(){
   [ -d ~/code/$1 ] || git clone git@bitbucket.org:demian0311/$1 ~/code/$1;
}

bitbucketGitRepo "wiki"

## Some Git work
find ~/code -name \.git  | sed s/\.git$// | xargs -I % sh -c 'cd %;  git diff --quiet || echo "% is dirty"'
find ~/code -name \.git  | sed s/\.git$// | xargs -I % sh -c 'cd %;  [[ -n $(git rev-list @{u}..HEAD) ]] &&  echo "% has unpushed commits"'

############################################################################################
#  ___ _   _ ___| |_ ___ _ __ ___    ___  ___| |_| |_(_)_ __   __ _ ___ 
# / __| | | / __| __/ _ \ '_ ` _ \  / __|/ _ \ __| __| | '_ \ / _` / __|
# \__ \ |_| \__ \ ||  __/ | | | | | \__ \  __/ |_| |_| | | | | (_| \__ \
# |___/\__, |___/\__\___|_| |_| |_| |___/\___|\__|\__|_|_| |_|\__, |___/
#      |___/                                                  |___/     
# 
# Lots of options exposed here: https://github.com/mathiasbynens/dotfiles/blob/master/.osx
###########################################################################################
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true
# Show the ~/Library folder
chflags nohidden ~/Library
# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true
# Set Safari’s home page to personal wiki
defaults write com.apple.Safari HomePage -string "http://localhost:4567"
# Hide Safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false
# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
# Enable the debug menu in Address Book
defaults write com.apple.addressbook ABShowDebugMenu -bool true
# Enable Dashboard dev mode (allows keeping widgets on the desktop)
defaults write com.apple.dashboard devmode -bool true
echo "system settings"

