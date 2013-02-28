#!/bin/bash
#
# /InstructionRecreate/startup.sh
#
# Creating an instruction based on a fileSet

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
na=$na
fileSet=$fileSet
keepLocationWhenRecreate=$keepLocationWhenRecreate

if [ ! "$keepLocationWhenRecreate" == "true" ] ; then
    keepLocationWhenRecreate="false"
fi

mongo $db --quiet --eval "var na='$na'; var label='$label'; var keepLocationWhenRecreate=$keepLocationWhenRecreate" $scripts/pmq-agents-available/InstructionRecreate/recreate.js

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

if [ ! -d $fileSet ] ; then
    mkdir -p $fileSet
    chown $na:$na $fileSet
    chmod 775 $fileSet
fi