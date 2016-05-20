#! /bin/bash

if [[ ! -e $JENKINS_HOME/jobs ]]
then
  cp -r /home/jenkins/jobs $JENKINS_HOME
fi

eval "exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "
