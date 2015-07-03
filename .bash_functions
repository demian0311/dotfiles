#!/bin/bash

function j7 {
   export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home
   export JAVA_HOME=$JRE_HOME
   export JDK_HOME=$JRE_HOME
   export PATH=$JAVA_HOME/bin:$PATH

   java -version
}

function j8 {
   #if [$HOSTNAME == 'thor']; then
   if [ "$HOSTNAME" = thor ]; then
      echo 'success'
      export JRE_HOME="$(/usr/libexec/java_home)"
      export JAVA_HOME=$JRE_HOME
      export JDK_HOME=$JRE_HOME
      export PATH=$JAVA_HOME/bin:$PATH
   else
      echo "not Thor, must be work computer"
      export JRE_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
      export JAVA_HOME=$JRE_HOME
      export JDK_HOME=$JRE_HOME
      export PATH=$JAVA_HOME/bin:$PATH
   fi

   java -version
}


function o-cd {
   cd ~/code/twc/online-bill-pay/
}

function o-cov {
   o-cd
   echo "OBP Coverage"
   ./grailsw test-app -unit -coverage -xml --non-interactive --plain-output
   if [ $? -ne 0 ]; then
      echo "something failed, will not open coverage report"
   else
      echo "opening coverage report"
      open ./target/test-reports/cobertura/index.html
   fi
}

function o-check {
   j8
   o-cd 
   ./grailsw codenarc

   if [ $? -ne 0 ]; then
      say "fail"
      echo "something failed, will not open codenarc"
   else
      say "pass"
      echo "opening coverage report"
      open ./target/CodeNarc-Report.html
   fi
}

function c-cd {
   cd ~/code/twc/cst/
}

function c-test {
   j8
   c-cd
   sbt test
}



// Layered

function r-cd {
   cd ~/code/layered/router/
}

function r-cov {
   j8
   r-cd
   cd ~/code/layered/router/
   ./gradlew clean
   ./gradlew cobertura 
   if [ $? -ne 0 ]; then
      echo "something failed, opening tests report"
      open ./build/reports/tests/index.html
   else 
      echo "opening coverage report"
      open ./build/reports/cobertura/index.html
   fi
}

function r-check {
   j8
   r-cd
   ./gradlew check

   if [ $? -ne 0 ]; then
      decho "fail"
      say "fail"
   else
      echo "pass"
      say "pass"
   fi
}

function r-mongo {
   mongod --dbpath ~/data/db
}
