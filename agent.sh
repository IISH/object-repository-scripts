#!/bin/bash

# Starts a message queue agent.

#Getting the parameters
while [ "${1+isset}" ]; do
     case "$1" in
	-shellScript )	shift
                        shellScript="$1"
                        ;;
        -messageQueue )	shift
                        messageQueue="$1"
                        ;;
	-maxTasks )	shift
                        maxTasks="$1"
                        ;;
	-log )        	shift
                        log="$1"
    esac
    shift
done

CMD="java -server -Dor.properties=$OR -jar $agent -shellScript $shellScript -messageQueue $messageQueue -maxTasks $maxTasks"
echo CMD=$CMD
$CMD > $log 2>&1 &
