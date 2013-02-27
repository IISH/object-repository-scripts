#!/bin/bash
#
# /StagingfileIngestPdf/startup.sh
#
# The convert script to create a pdf document, once all material is completed.

scripts=$scripts
source $scripts/shared/parameters.sh

if [ "$action" == "delete" ] ; then
    exit 0
fi

for sourceBucket in level2 level1 master
do
	echo "sourceBucket='$sourceBucket'"
	sourceFile=$(mongo $db --quiet --eval "var doc=db.$sourceBucket.files.findOne({'metadata.pid','metadata.seq':{\$gt:0}},contentType:/^image/}); \
	     if ( doc ) {var objid=(doc.metadata.objid) ? doc.metadata.objid : '$label';  print('$tmp/$na/' + objid + '_' + doc.metadata.seq + '_' +  doc.filename)}")
    if [ ! -z "$sourceFile" ]; then
        echo "sourceFile=$sourceFile"
        if [ -f "$sourceFile" ]; then
	        echo "Using existing cached file on $sourceFile"
	        break
        else
	        l=$sourceFile
	        source $scripts/shared/get.sh
	        if [ -f "$sourceFile" ] ; then
	            echo "Using db file on $sourceFile"
	            break
	        fi
	    fi
    fi
done

# If we downloaded all images we will produce the PDFs