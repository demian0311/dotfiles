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

function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

	# Just calculate this once, to save a few cycles when displaying the prompt
	if not set -q __fish_prompt_hostname
		set -g __fish_prompt_hostname (hostname|cut -d . -f 1)
	end

	set -l normal (set_color normal)

	# Hack; fish_config only copies the fish_prompt function (see #736)
	if not set -q -g __fish_classic_git_functions_defined
		set -g __fish_classic_git_functions_defined

		function __fish_repaint_user --on-variable fish_color_user --description "Event handler, repaint when fish_color_user changes"
			if status --is-interactive
				commandline -f repaint ^/dev/null
			end
		end

		function __fish_repaint_host --on-variable fish_color_host --description "Event handler, repaint when fish_color_host changes"
			if status --is-interactive
				commandline -f repaint ^/dev/null
			end
		end

		function __fish_repaint_status --on-variable fish_color_status --description "Event handler; repaint when fish_color_status changes"
			if status --is-interactive
				commandline -f repaint ^/dev/null
			end
		end

		function __fish_repaint_bind_mode --on-variable fish_key_bindings --description "Event handler; repaint when fish_key_bindings changes"
			if status --is-interactive
				commandline -f repaint ^/dev/null
			end
		end

		# initialize our new variables
		if not set -q __fish_classic_git_prompt_initialized
			set -qU fish_color_user; or set -U fish_color_user -o green
			set -qU fish_color_host; or set -U fish_color_host -o cyan
			set -qU fish_color_status; or set -U fish_color_status red
			set -U __fish_classic_git_prompt_initialized
		end
	end

	set -l color_cwd
	set -l prefix
	switch $USER
	case root toor
		if set -q fish_color_cwd_root
			set color_cwd $fish_color_cwd_root
		else
			set color_cwd $fish_color_cwd
		end
		set suffix '#'
	case '*'
		set color_cwd $fish_color_cwd
		set suffix '>'
	end

	set -l prompt_status
	if test $last_status -ne 0
		set prompt_status ' ' (set_color $fish_color_status) "[$last_status]" "$normal"
	end

	set -l mode_str
	switch "$fish_key_bindings"
	case '*_vi_*' '*_vi'
		# possibly fish_vi_key_bindings, or custom key bindings
		# that includes the name "vi"
		set mode_str (
			echo -n " "
			switch $fish_bind_mode
			case default
				set_color --bold --background red white
				echo -n "[N]"
			case insert
				set_color --bold green
				echo -n "[I]"
			case visual
				set_color --bold magenta
				echo -n "[V]"
			end
			set_color normal
		)
	end

	echo -n -s (set_color $fish_color_user) "$USER" $normal @ (set_color $fish_color_host) "$__fish_prompt_hostname" $normal ' ' (set_color $color_cwd) (prompt_pwd) $normal (__fish_git_prompt) $normal $prompt_status "$mode_str" "> "
end
