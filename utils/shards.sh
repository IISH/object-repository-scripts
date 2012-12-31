#!/bin/bash
#
# shards.sh
#
# Recreates the config/shards collection according to the shards defined interval
#

scripts=$scripts
shards=$shards
dbs=$dbs

for db in ${dbs[*]}
do
    for ns in level3.chunks level2.chunks level1.chunks master.chunks
    do
        mongo test --quiet --eval "var shards=$shards; var db='$db'; var ns='$ns'" $scripts/utils/shards.js
    done
done