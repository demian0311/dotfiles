#!/bin/bash

# Start an HTTP server from a directory, optionally specifying the port
function servedir() {
	local port="${1:-8000}";
	sleep 1 && open "http://localhost:${port}/" &
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

# a nicer tree piped to less
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRX;
}

# DNS help
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer;
}

function j7 {
   export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home
   export JAVA_HOME=$JRE_HOME
   export JDK_HOME=$JRE_HOME
   export PATH=$JAVA_HOME/bin:$PATH

   java -version
}

function j8 {
   if [ "$HOSTNAME" = thor ]; then
      export JRE_HOME="$(/usr/libexec/java_home)"
      export JAVA_HOME=$JRE_HOME
      export JDK_HOME=$JRE_HOME
      export PATH=$JAVA_HOME/bin:$PATH
   else
      export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
      export JAVA_HOME=$JRE_HOME
      export JDK_HOME=$JRE_HOME
      export PATH=$JAVA_HOME/bin:$PATH
   fi
   #java -version
}

function pass {
   echo -e "$(tput setaf 2)##### PASS #####$(tput sgr0)"
   say "pass"
}

function fail {
   echo -e "$(tput setaf 1)##### FAIL #####$(tput sgr0)"
   say "fail"
}

function cd.r {
   cd ~/code/onvoy/router/
}

function cd.h {
   cd ~/code/onvoy/heimdall/
}

function cd.a {
   cd ~/code/onvoy/asgard/
}

function g.test {
   j8
   ./gradlew test 
   if [ $? -ne 0 ]; then
      fail
      open ./build/reports/tests/index.html
   else
      pass
   fi

}

function g.cov {
   j8
   ./gradlew clean cobertura
   if [ $? -ne 0 ]; then
      fail
      open ./build/reports/tests/index.html
   else
      pass
      open ./build/reports/cobertura/index.html
   fi
}

function g.check {
   j8
   ./gradlew check

   if [ $? -ne 0 ]; then
      fail
   else
      pass
   fi
}

function g.mutest {
   j8
   ./gradlew pitest
   if [ $? -ne 0 ]; then
      fail
   else
      pass
      open $(find ./build/reports/pitest -name index.html | head -n 1)
   fi
}

function g.run {
   j8
   PROJECT=`basename $PWD`
   tail -f ${PROJECT}.log &
   echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
   ./gradlew bootRun 
}
