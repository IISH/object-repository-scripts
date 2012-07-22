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

OR_HOME=$OR_HOME
OR=$OR
agent=$agent
log=$OR_HOME/log/agent.$(date +%Y-%m-%d).log

if [ "$1" = "start" ] ; then
    CMD="java -server -Dor.properties=$OR -jar $agent -id $HOSTNAME -messageQueues $OR_HOME/pmq-agents-enabled"
    $CMD > $log 2>&1 &
else
    brokerURL=$brokerURL:8161
    wget --post-data "body=$1" $brokerURL/demo/message/Connection?type=topic
fi