#!/bin/bash
#
# Remove a file when it ends with .md5

f="$1"

if [ -f "$f" ] ; then
    if [[ "$f" == *.md5 ]]
    then
        echo "Remove md5 file ${f}"
        rm -f "$f"
    fi
fi
