#!/bin/bash
#
# /InstructionAutocreate/startup.sh
#
# Creating an instruction automatically

scripts=$scripts
source $scripts/shared/instruction.sh

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

# Verify if the task did it's job
fileSet=$fileSet
count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet'}).count()")
if [ $count == 0 ] ; then
    echo "No files were declared for fileSet: $fileSet"
    exit -1
fi

exit 0
