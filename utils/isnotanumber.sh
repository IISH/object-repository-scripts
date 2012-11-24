#!/bin/bash

cat $1 | while read l
do
    if ! [[ "$l" =~ ^[-0-9]+$ ]] ; then
        echo $l
    fi
done
