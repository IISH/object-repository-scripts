#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 2 derivative
# Here we create 4 x 4 stilled images
#
# The -r option specifies the frame rate of the output stream (which is an image sequence).
# Calculate the frame rate from the following expression:
# r = (number of desired frames + 1) / input_duration
#
# Example: movie duration of 'input.avi' is 273 seconds; and 16 stills are needed, apply:
# let r=16+1 / 273 = 0.06227106227106227106227106227106
# ffmpeg -i input.avi -f image2 -r $r -s qvga frame-%05d.png

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh
sourceBuckets="level1 master"
bucket=level2
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
pid=$pid
imParams=$(mongo $db --quiet --eval "var desired_frames = 16; \
var r = 0; \
ss = 0; \
var doc = db.master.files.findOne({'metadata.pid':'$pid'}, {'metadata.content':1}); \
if (doc) doc.metadata.content.streams.forEach(function (d) { \
    if (d.codec_type == 'video') { \
        desired_frames++; \
        r = desired_frames / d.duration; \
        ss = d.duration / (desired_frames"\*"10); \
    }}); \
if (r == 0) print('-vframes 16'); else print('-r ' + r + ' -ss ' + ss); \
")

ffmpeg -i $sourceFile -f image2 $imParams $tmp/$md5.$bucket-%05d.png
rm $sourceFile

contentType="image/jpeg"
l=$tmp/$md5.$bucket.jpg
montage $tmp/$md5.$bucket-* -geometry 320x+4+4 -frame 1 $l # see http://www.imagemagick.org/Usage/montage/
rm $tmp/$md5.$bucket-*

if [ ! -f $l ] ; then
    echo "Montage failed to assemble a set of stilled images from the source file."
    exit -1
fi

md5=$(md5sum $l | cut -d ' ' -f 1)
echo "$md5  $l" > "$l.md5"
remove="yes"
$scripts/shared/put.sh

exit $?