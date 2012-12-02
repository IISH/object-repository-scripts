#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 3 derivative

scripts=$scripts
source $scripts/shared/parameters.sh
sourceBuckets="level1 master"
bucket=level3
md5=$md5
tmp=$derivative_cache

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

sourceBucket=level1
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
imParams=$(mongo $db --quiet --eval "var ss = 10; \
var m = db.$sourceBucket.files.findOne({'metadata.pid':'$pid'}, {'metadata.content.format':1}); \
if (m) { \
    var format=m.metadata.content.format; \
    ss = Math.round(format.duration / 2); \
    }; \
print('-ss ' + ss); \
")

contentType="image/jpeg"
l=$tmp/$md5.$bucket.jpg
tmp=$tmp/$md5.$bucket.bmp
ffmpeg -y -i $sourceFile -an $imParams -vframes 1 $tmp
if [ ! -f $tmp ] ; then
    echo "Extracting a still failed."
    exit -1
fi

rm $sourceFile

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
length=$(stat -c%s "$l")
echo "$md5  $l" > "$l.md5"
remove="yes"
source $scripts/shared/put.sh

exit $?