#!/bin/bash
#
# Runs ImageMagick to convert an image into a ( smaller ) image.
# Then ingests the derivative into the correct bucket.
#
sa_path=$sa_path
scripts=$scripts
db=$db
pid=$pid
md5=$md5
sourceBuckets=$sourceBuckets
bucket=$bucket
tmp=$derivative_cache
targetFile=$tmp/$md5.$bucket

for sourceBucket in ${sourceBuckets[*]}
do
	echo "sourceBucket='$sourceBucket'"
    if [ ! "$sourceBucket" == "master" ]; then
        sourceFileExtension="jpeg"
    fi
    sourceFile=$tmp/$md5.$sourceBucket.$sourceFileExtension
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
if [ -f "$sourceFile" ]; then
	echo "Creating derivative from $sourceFile"
	php $scripts/shared/image.derivative.php -i $sourceFile -l $bucket -b $sourceBucket -d $db -p $pid -s $scripts/shared/content.js -o $targetFile
else
	echo "Could not find a master or higher level derivative to produce a $bucket file"
	echo "We need at least a master to produce a derivative."
	exit 240
fi

# Sometimes the original files was a multipaged file. We correct this here.
# The derivative script has added a jpg extension to the targetFile, which we take over here.
mpf=$targetFile-0.jpg
targetFile="$targetFile.jpg"
if [ -f $mpf ] ; then
    mv -f $mpf $targetFile
    rm $tmp/$md5.$bucket-*
fi

if [ -f "$sourceFile" ]; then
    rm $sourceFile
fi

if [ -f "$targetFile" ]; then
	contentType="image/jpeg"
	l="$targetFile"
	md5=$(md5sum "$targetFile" | cut -d ' ' -f 1)
	echo "$md5  $targetFile" > "$targetFile.md5"
	remove="yes"
	source $scripts/shared/put.sh
else
	echo "Unable to create derivative."
	exit 240
fi
