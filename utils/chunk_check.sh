#!/bin/bash

db=$1
ns=$2
_id=$3

file=chunk.check.$db.$ns.txt
mongo $db --eval "var ns='$ns'; var _id='$_id'" /usr/bin/object-repository/scripts/utils/chunk_check.js > $file
