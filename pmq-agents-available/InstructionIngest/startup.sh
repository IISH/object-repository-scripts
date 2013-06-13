#!/bin/bash
#
# /InstructionIngest/startup.sh

scripts=$scripts
source $scripts/shared/parameters.sh

q="fileSet:'$fileSet'"
count=$(mongo sa --quiet --eval "db.stagingfile.count({$q, workflow:{\$elemMatch:{n:0, name:'InstructionValidated', statusCode:{\$lt:800}}}})")
if [[ $count != 0 ]] ; then
    echo "$count staging file elements did not passed validation. Correct the problems first before starting the ingest."
    exit -1
fi

# Set the start and end dates correctly. Hence we set that here.
# We set the end date in the past so the workflow controller will pick up on it.
lasterror=$(mongo sa --quiet --eval "db.stagingfile.update({$q}, \
    {\$set:{workflow:[{ \
        n:0, name:'Start', statusCode:100, start:new Date(), end:new Date(0), total:0, processed:0, \
        attempts:1, limit:3, exitValue:2147483647, info:'Starting InstructionIngest' \
        }]}}, \
        false, true); \
        db.runCommand({getlasterror:1, w:'majority'}).err")
rc=$?
if [[ $rc != 0 ]] ; then
    echo $lasterror
    exit $rc
fi

exit 0