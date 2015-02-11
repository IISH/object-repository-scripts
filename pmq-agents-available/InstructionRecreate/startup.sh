#!/bin/bash
#
# /InstructionRecreate/startup.sh
#
# Creating an instruction based on a label

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
na=$na
fileSet=$fileSet
id=$id

mongo $db --quiet --eval "var na='$na'; var id='$id';" $scripts/pmq-agents-available/InstructionRecreate/recreate.js

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

if [ ! -d $fileSet ] ; then
    mkdir -p $fileSet
    owner_folder=$(dirname "$fileSet")
    owner=$(ls -ld $owner_folder | awk '{print $3}')
    chown $owner:$na $fileSet
    chmod 775 $fileSet
fi