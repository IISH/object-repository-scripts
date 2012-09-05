#!/bin/bash
#
# primary.sh
#
# ensures the MongoDB primaries are those servers we want them to be.

scripts=$scripts

ok=$($scripts/shared/timeout.sh $scripts/shared/primaries.sh)
if [ ! $ok = "ok" ] ; then
    echo "Timeout when looking for the primaries"
    exit -1
fi


