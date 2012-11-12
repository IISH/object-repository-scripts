#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 3 derivative

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh
sourceBuckets="level1 master"
bucket=level2
md5=$md5
tmp=$tmp

action=$action
if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

for sourceBucket in ${sourceBuckets[*]}
do
	echo "sourceBucket='$sourceBucket'"
    sourceFile=$tmp/$md5.$sourceBucket
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
done

# Run the convert script to create derivative.
if [ ! -f "$sourceFile" ]; then
	echo "Could not find a master or higher level derivative to produce a sourceBucket file"
	echo "We need at least a master to produce a derivative."
	exit 240
fi

# Construct the correct parameters for the extraction of stilled images
db=$db
imCmd=$(mongo $db --quiet --eval "var ss=10;var doc=db.master.files.findOne('metadata.pid':'\$pid',{'metadata.content':1}); \
    if (doc) {\
        doc.metadata.content.streams.forEach(function(d){if (d.codec_type=='video ') { \
            ss = Math.round(d.duration / 2); \
            }})}; \
            print('-ss ' + ss);
            ")

l=$tmp/$md5.$bucket.jpg
ffmpeg -y -i $sourceFile -vframes 1 $imCmd -an -vcodec jpg -f rawvideo -s 320x $l
if [ ! -f $l ] ; then
    echo "Extracting a still failed."
    exit -1
fi

md5=$(md5sum $l | cut -d ' ' -f 1)
echo "$md5  $l" > "$l.md5"
remove="yes"
$scripts/shared/put.sh

exit $?