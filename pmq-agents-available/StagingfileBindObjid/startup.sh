#!/bin/bash
#
# /StagingfileBindObjid/startup.sh
#
# The convert script to bind the mets obj document
#
# We bind the main PID: objid with the 'master' ( mets xml )

scripts=$scripts
source $scripts/shared/parameters.sh

if [ "$action" == "delete" ] ; then
    exit 0
fi

if [ -z "$objid" ] ; then
    echo "No objid.... exiting"
    exit 245
fi

# Are there any task still staged related to the objid, save this one ?
# StatusCode ought to be 850 (problems) or 900
# That means if this really is the last task
count=$(mongo sa --eval "db.stagingfile.count({fileSet: '$fileSet', objid:'$objid', workflow: { /
    \$elemMatch: {n:0, 'StagingfileIngestObjid', statusCode: {\$lt: 900}}}})")
if [ $count != 1 ] ; then
    echo "Workflow not yet ready to produce a pdf."
    exit 245
fi

# Determine the level we can use to produce a pfd of. Return the highest seq value.
for sourceBucket in level2 level1 master
do
	seqMax=$(mongo $db --quiet --eval "var doc=db.master.files.find( {'metadata.objid':'10622/ARCH02550.1031', /
	    contentType:/^image\//}).limit(1).sort({'metadata.seq':-1})[0];if (doc) print(doc.metadata.seq);")
    if [ ! -z "$seqMax" ]; then
        echo "Using sourceBucket=$sourceBucket. Expecting $seqMax files"
	    break
    fi
done

echo "$countFiles of $countSAFiles are available to produce a pfd... skipping"
exit 0