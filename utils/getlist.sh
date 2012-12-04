#!/bin/bash

from=$1
if [ -z "$from" ] ; then
    echo Need a limit.
    exit -1
fi

if ! [[ "$from" =~ ^[-0-9]+$ ]] ; then
    echo "$from is not a number."
    exit -1
fi

mongo or_10622 --quiet --eval "db.master.files.find( {}, {_id:1, 'metadata.pid':1 } ).skip($from).limit(1000).forEach( \
    function(d){if(d._id.length>20)print('\$scripts/utils/change.key.sh '+d._id + ' ' + d.metadata.pid)});" > change.keys.$from.sh

chmod 744 change.keys.$from.sh