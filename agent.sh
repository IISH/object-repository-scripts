#!/bin/bash
# Starts a message queue agent.
#
OR=$OR
agent=$agent

#Getting the parameters
while [ "${1+isset}" ]
do
     case "$1" in
    -shellScript )      shift
        shellScript="$1"
                        ;;
    -messageQueues )    shift
        messageQueues="$1"
                        ;;
        -maxTasks )     shift
        maxTasks="$1"
                        ;;
        -log )          shift
        log="$1"
    esac
    shift
done

CMD="java -server -Dor.properties=$OR -jar $agent -shellScript $shellScript -messageQueues $messageQueues -maxTasks $maxTasks"
$CMD > $log 2>&1 &