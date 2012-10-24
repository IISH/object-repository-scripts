#!/bin/bash
#
# primary.sh
#
# ensures the MongoDB primaries are those servers we want them to be.

scripts=$scripts
primaries=$primaries
for primary in ${primaries[*]}
do
    ismaster="false"
    ismaster=$(timeout 5 mongo $primary --quiet --eval "db.serverStatus().repl.ismaster")
    if [ ! "$ismaster" = "true" ] ; then
        echo "$primary is not primary; ismaster=$ismaster"
        exit -1
    fi
done

