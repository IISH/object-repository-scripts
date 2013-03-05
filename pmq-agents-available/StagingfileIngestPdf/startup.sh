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

item=$(db.master.files.findOne( { \$or: [ {'metadata.label':'$label'} , {'metadata.pid':'$pid'} ] } );

for sourceBucket in level2 level1 master
do
	echo "sourceBucket='$sourceBucket'"
	sourceFile=$(mongo $db --quiet --eval "function format(d){var seq='0000'+d;return seq.substring(seq.length-4)};var doc=db.$sourceBucket.files.findOne({'metadata.pid':$pid,'metadata.seq':{\$gt:0},'metadata.objid':{\$exists:true},contentType:/^image/}); \
	     if ( doc ) print('$tmp/$na/' + doc.metadata.objid + '_' + format(doc.metadata.seq) + '_' +  doc.filename)")
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

# Once we have downloaded all images we will produce the PDF
folder=$(dirname $sourceFile)
countFiles=$(find $folder -type f | wc -l)
countSAFiles=0
if [ "$countFiles" == "$countSAFiles" ] ; then
    exit 245
fi

echo "$countFiles of $countSAFiles are available to produce a pfd... skipping"
exit 0