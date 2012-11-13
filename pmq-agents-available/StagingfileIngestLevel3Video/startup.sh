#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 3 derivative

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh
sourceBuckets="level1 master"
bucket=level3
md5=$md5
tmp=$derivative_cache

action=$action
if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

db=$db
if [ "$db" == "or_10622" ] ; then
    echo "proceed"
else
    source $scripts/shared/video.derivative.sh
fi

for sourceBucket in ${sourceBuckets[*]}
do
	echo "sourceBucket='$sourceBucket'"
    sourceFile=$tmp/$md5.$sourceBucket.jpg
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
pid=$pid
imParams=$(mongo $db --quiet --eval "var ss = 10; \
var doc = db.master.files.findOne({'metadata.pid':'$pid'}, {'metadata.content':1}); \
if (doc) doc.metadata.content.streams.forEach(function (d) { \
    if (d.codec_type == 'video') { \
        ss = d.duration / 2; \
    }}); \
print('-ss ' + ss); \
")

l=$tmp/$md5.$bucket.jpg
tmp=$tmp/$md5.$bucket.bmp
ffmpeg -y -i $sourceFile -vcodec libx264 -an $imParams $tmp
if [ ! -f $tmp ] ; then
    echo "Extracting a still failed."
    exit -1
fi

# reduce to a width of at least 320 px
min=320
width=$(identify -format "%w" "$tmp")
if [ $width -lt $min ] ; then
    convert $tmp $l
else
    convert $tmp -thumbnail "$min"x $l
fi
rm $tmp

md5=$(md5sum $l | cut -d ' ' -f 1)
echo "$md5  $l" > "$l.md5"
remove="yes"
$scripts/shared/put.sh

exit $?