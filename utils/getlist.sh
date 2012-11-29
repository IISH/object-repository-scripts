#!/bin/bash

limit=$1
if [ -z "$limit" ] ; then
    echo Need a limit.
    exit -1
fi

if ! [[ "$limit" =~ ^[-0-9]+$ ]] ; then
    echo "$limit is not a number."
    exit -1
fi

mongo or_10622 --quiet --eval "db.master.files.find( {}, {_id:1, 'metadata.pid':1 } ).skip($limit).limit(1000).forEach( \
    function(d){if(d._id.length>20)print('\$scripts/utils/change.key.sh '+d._id + ' ' + d.metadata.pid)});" > change.keys.$limit.sh

chmod 744 change.keys.$limit.sh