#!/bin/bash

n=$(lsof | grep mongo | grep TCP | wc)
tcp=0$(echo $n | rev | cut -d" " -f1)
echo "TCP connection number is $tcp"
if [ $tcp -gt 8000 ] ; then
    echo "Rather large... restarting mongos..."
	service mongos restart
fi