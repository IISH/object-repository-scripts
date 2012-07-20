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

log=$OR_HOME/log/agent.$(date +%Y-%m-%d).log
$scripts/agent.sh -id $HOSTNAME -maxTasks 1 -shellScript startup.sh -messageQueues $OR_HOME/pmq-agents-enabled -log $log