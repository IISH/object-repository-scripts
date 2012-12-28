#!/bin/bash
#
# /InstructionIngest/startup.sh

scripts=$scripts
source $scripts/shared/instruction.sh

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

# Lets see if all stagingfiles have a default task 'Start'. In fact we look for alternative tasks who really should not
# be there at all.
fileSet=$fileSet

# The application does not set the start and end dates correctly. Hence we set that here.
mongo sa --quiet --eval "db.getCollection('stagingfile').update({fileSet:'$fileSet', 'workflow.name':'Start'}, \
    {\$set:{'workflow.\$.start':new Date(), 'workflow.\$.end':new Date()}}, \
    false, true)"

count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet', \
    \$or:[{'workflow.n':{\$exists:false}},{'workflow.n':0,'workflow.name':{\$ne:'Start'}}]}).count()")
if [ $count != 0 ] ; then
    echo "$count declared files do not have the expected 'Start' task: $fileSet"
    exit -1
fi


exit 0
