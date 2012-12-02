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
source $scripts/shared/parameters.sh
sourceBuckets="level1 master"
bucket=level2
md5=$md5
tmp=$derivative_cache

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

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
var m = db.$sourceBucket.files.findOne({'metadata.pid':'$pid'}, {'metadata.content.format':1}); \
if (m) { \
    var format=m.metadata.content.format; \
    desired_frames++; \
    r = Math.round(desired_frames "\*" 1000 / format.duration) / 1000; \
    ss = Math.round( format.duration "\*" 1000 / (desired_frames "\*" 10))/1000; \
    }; \
if (r == 0) print('-vframes 16'); else print('-r ' + r + ' -ss ' + ss); \
")

ffmpeg -i $sourceFile -an -f image2 $imParams $tmp/$md5.$bucket-%02d.png
rm $sourceFile

contentType="image/jpeg"
l=$tmp/$md5.$bucket.jpg
#roundError=$tmp/$md5.$bucket-17.png # sometimes there is one too many
#if [ -f $roundError ] ; then rm $roundError ; fi
montage $tmp/$md5.$bucket-* -geometry 320x+4+4 -frame 1 $l # see http://www.imagemagick.org/Usage/montage/
rm $tmp/$md5.$bucket-*

if [ ! -f $l ] ; then
    echo "Montage failed to assemble a set of stilled images from the source file."
    exit -1
fi

md5=$(md5sum $l | cut -d ' ' -f 1)
length=$(stat -c%s "$l")
echo "$md5  $l" > "$l.md5"
remove="yes"
source $scripts/shared/put.sh

exit $?
