#!/bin/bash

####################################################################
# Shuts down the agent:
# /shutdown.sh "kill [identifier]"
# example: /shutdown.sh "kill $HOSTNAME"
#
# Shuts down all agents that listen to the message queue:
# /shutdown.sh kill
#
####################################################################

brokerURL=$brokerURL:8161
wget --post-data "body=$1" $brokerURL/demo/message/Connection?type=topic