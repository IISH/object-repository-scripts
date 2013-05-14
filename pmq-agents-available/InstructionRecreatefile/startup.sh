#!/bin/bash
#
# /InstructionRecreatefile/startup.sh
#
# Creating a fileset based on an existing instruction

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
na=$na
fileSet=$fileSet
id=$id

mongo $db --quiet --eval "var id='$id';" $scripts/pmq-agents-available/InstructionRecreatefile/recreate.js

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

if [ ! -d $fileSet ] ; then
    mkdir -p $fileSet
    chown $na:$na $fileSet
    chmod 775 $fileSet
fi