#!/bin/bash

from=$1
if [ -z "$from" ] ; then
    echo Need a limit.
    exit -1
fi

if ! [[ "$from" =~ ^[-0-9]+$ ]] ; then
    echo "from $from is not a number."
    exit -1
fi

to=$2
if [ -z "$to" ] ; then
    echo Need a limit.
    exit -1
fi

if ! [[ "$to" =~ ^[-0-9]+$ ]] ; then
    echo "to $to is not a number."
    exit -1
fi

file=change.keys.$from.$to.sh
mongo or_10622 --quiet --eval "var i=0;db.master.files.find({},{_id:1,'metadata.pid':1}).forEach(function(d){if(d._id.length>20){i++;if(i>$from && i<$to) print('source \$scripts/utils/change.key.sh '+d._id+' '+d.metadata.pid)}})">$file
chmod 744 $file