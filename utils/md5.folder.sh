#!/bin/bash

scripts=$scripts
if [ -d "$1" ] ; then
        find "$1" -type f -exec $scripts/utils/md5.file.sh {} \;
fi
