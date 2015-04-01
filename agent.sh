#!/bin/bash
#
# Start agent: ./agent.sh start
#
# Stop agent: ./agent.sh stop $HOSTNAME
# Pause agent: ./agent.sh $HOSTNAME
# Continue agent: ./agent.sh continue $HOSTNAME
#
# Stop all agents: ./agent.sh stop
# Pause all agents: ./agent.sh pause
# Continue all agents: ./agent.sh continue

source /etc/environment

OR_HOME=$OR_HOME
OR=$OR
agent=$agent
log=$OR_HOME/log/agent.$(date +%Y-%m-%d).log

scope=$2
if [ "$scope" = "" ] ; then
    scope=$HOSTNAME
fi

if [ "$scope" = "$HOSTNAME" ] || [ "$scope" = "all" ] ; then
    if [ "$1" = "start" ] ; then
        if [ -z "$CYGWIN_HOME" ] ; then
            CMD="java -server -Dor.properties=$OR -jar $agent -id $HOSTNAME -messageQueues $OR_HOME/pmq-agents-enabled"
        else
            CMD="java -server -Dor.properties=$(cygpath --windows $OR) -jar $(cygpath --windows $agent) -id $HOSTNAME -messageQueues $(cygpath --windows $scripts)/pmq-agents-available -startup \"\startup.bat\""
        fi
        $CMD > $log 2>&1 &
    else
        brokerURL=$brokerURL:8161
        wget -O tmp.txt --post-data "body=$1 $scope" $brokerURL/demo/message/Connection?type=topic
        rm tmp.txt
    fi
else
    echo "Invalid command: $scope"
    exit -1
fi