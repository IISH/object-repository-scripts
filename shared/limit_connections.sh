#!/bin/bash

n=$(lsof | grep mongo | grep TCP | wc)
tcp=0$(echo $n | rev | cut -d" " -f1)
if [ $tcp -gt 10000 ] ; then
    echo "Warning: TCP connection number is $tcp... seems rather high"
fi