#!/bin/bash

d=$1
if [ -d $d ] ; then
        find $1 -type f -exec md5.file.sh {} \;
fi
