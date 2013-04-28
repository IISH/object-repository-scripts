#!/bin/bash
#
# /InstructionIngest/startup.sh

scripts=$scripts
source $scripts/shared/instruction.sh

rc=$?
if [[ $rc != 0 ]] ; then
    mongo sa --quiet --eval "db.getCollection('stagingfile').update({fileSet:'$fileSet'}, \
        {\$unset:{workflow:1}}, false, true)"
    exit $rc
fi

# Lets see if all stagingfiles have a default task 'Start'.
# In fact we look for alternative tasks who really should not be there at all.
fileSet=$fileSet
count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet', \
    \$or:[{'workflow.n':{\$exists:false}},{'workflow.n':0,'workflow.name':{\$ne:'Start'}}]}).count()")
if [[ $count != 0 ]] ; then
    echo "$count declared files do not have the expected 'Start' task: $fileSet"
    echo "Undo any tasks"
    mongo sa --quiet --eval "db.getCollection('stagingfile').update({fileSet:'$fileSet'}, \
        {\$unset:{workflow:1}}, false, true)"
    exit -1
fi

# The application does not set the start and end dates correctly. Hence we set that here.
# We set the end date in the past so the workflow controller will pick up on it.
lasterror=$(mongo sa --quiet --eval "db.getCollection('stagingfile').update({fileSet:'$fileSet', 'workflow.name':'Start'}, \
    {\$set:{'workflow.\$.start':new Date(), 'workflow.\$.end':new Date(0)}}, \
    false, true);db.runCommand({getlasterror:1, w:'majority'}).err")
rc=$?
if [[ $rc != 0 ]] ; then
    echo $lasterror
    exit $rc
fi

exit 0