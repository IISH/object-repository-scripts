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
    for c in level3.files level2.files level1.files master.files
    do
        mongo config --quiet --eval "var shards=$shards; var db='$db'; var bucket='$c'" $scripts/utils/shards.js
    done
done