#!/bin/bash
#
# /InstructionRecreate/startup.sh
#
# Creating an instruction based on a pid value in the workflow task info field.

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
na=$na
fileSet=$fileSet
id=$id

mongo $db --quiet --eval "var na='$na'; var id='$id';" $scripts/pmq-agents-available/InstructionRecreatefile/recreate.js

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

if [ ! -d $fileSet ] ; then
    mkdir -p $fileSet
    chown $na:$na $fileSet
    chmod 775 $fileSet
fi