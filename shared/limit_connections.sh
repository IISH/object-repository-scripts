#!/bin/bash

n=$(lsof | grep mongod | grep TCP | wc)
tcp=0$(echo $n | rev | cut -d" " -f1)
echo "TCP connection number is $tcp"
if [ $tcp -gt 9000 ] ; then
    echo "Rather large... restarting mongos..."
	service mongos restart
fi