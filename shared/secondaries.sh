#!/bin/bash
#
# secondaries.sh
#
# ensures the MongoDB secondaries are those servers we expect them to be.

scripts=$scripts
secondaries=$secondaries
for secondary in ${secondaries[*]}
do
    issecondary="false"
    issecondary=$(timeout 5 mongo $secondary --quiet --eval "db.serverStatus().repl.secondary")
    if [ ! "$issecondary" == "true" ] ; then
        echo "$secondary is not secondary but db.serverStatus().repl.issecondary=$issecondary"
        exit -1
    fi
done

