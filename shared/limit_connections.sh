#!/bin/bash

n=$(lsof | grep mongod | grep TCP | wc)
tcp=0$(echo $n | rev | cut -d" " -f1)
if [ $tcp -gt 10000 ] ; then
    echo "TCP connection number of $tcp is rather large. Restarting mongos..."
	service mongos restart
fi