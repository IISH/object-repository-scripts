#!/bin/bash

####################################################################
# Set the following variables;
# Add them as exported environment variables in /etc/environment
#
# Home directory that contains the script folder and any symbolic linkages
# export OR_HOME=/opt/object-repository

# or.properties
# export OR=/opt/object-repository/conf/or.properties

# Scripts folder
# export scripts=/usr/bin/object-repository/scripts

# Applications
# export orfiles=/usr/bin/object-repository/orfiles.jar
# export manager=/usr/bin/object-repository/instruction-manager.jar

# PID webservice key
# export key=

# PID webservice endpoint
# export endpoint=https://pid.socialhistoryservices.org/secure

# Sor resolve URL
# export resolveUrl=http://localhost

# MongoDB storage, replica set
# export host=localhost
# export database=or
# export stagingarea=sa
# export sa_path=/mnt/sa

# export brokerURL=localhost:61616
#
####################################################################

OR_HOME=$OR_HOME
scripts=$scripts

# Iterate over the startup folder and initialize a pmq agent for each
FILES=$OR_HOME/pmq-agents-enabled/*
for f in $FILES
do
     shellScript=$f/startup.sh
     messageQueue=$(basename $f)
     log=$OR_HOME/log/$messageQueue.$(date +%Y-%m-%d).log

     maxTasks=2
     setenv=$f/setenv.sh
     if [ -f "$setenv" ] ; then
         source $setenv
     fi
     echo "Starting agent for $messageQueue"
     $scripts/agent.sh -shellScript $shellScript -messageQueue $messageQueue -maxTasks $maxTasks -log $log
     sleep 1
done
