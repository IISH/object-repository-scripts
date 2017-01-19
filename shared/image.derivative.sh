#!/bin/bash
#
# Runs ImageMagick to convert an image into a ( smaller ) image.
# Then ingests the derivative into the correct bucket.
#
sa_path=$sa_path
scripts=$scripts
db=$db
id=$id
pid=$pid
sourceBuckets=$sourceBuckets
sourceFileExtension=$sourceFileExtension
bucket=$bucket
tmp=$derivative_cache
targetFile=$tmp/$id.$bucket

for sourceBucket in ${sourceBuckets[*]}
do
	echo "sourceBucket='$sourceBucket'"
    if [ ! "$sourceBucket" == "master" ]; then
        sourceFileExtension="jpeg"
    fi
    sourceFile=$tmp/$id.$sourceBucket.$sourceFileExtension
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
	echo "Creating ${bucket} derivative from ${sourceFile}"
	cmd=$(/usr/bin/php "${scripts}/shared/image.derivative.php" -i "$sourceFile" -b "$bucket" -o "$targetFile")
	rc=$?
    if [[ $rc == 0 ]] ; then
        echo "Running conversion: ${cmd}"
        eval "$cmd"
    else
        echo "Error: ${cmd}"
    fi
else
	echo "Could not find a master or higher level derivative to produce a $bucket file"
	echo "We need at least a ${bucket} to produce a derivative."
	exit 240
fi

# Sometimes the original files was a multipaged file. We correct this here.
# The derivative script has added a jpg extension to the targetFile, which we take over here.
mpf=$targetFile-0.jpg
targetFile="$targetFile.jpg"
if [ -f $mpf ] ; then
    mv -f $mpf $targetFile
    rm $tmp/$id.$bucket-*
fi

if [ -f "$sourceFile" ]; then
    rm $sourceFile
fi

if [ -f "$targetFile" ]; then
	contentType="image/jpeg"
	l="$targetFile"
	length=$(stat -c%s "$l")
	md5=$(md5sum "$targetFile" | cut -d ' ' -f 1)
	echo "$md5  $targetFile" > "$targetFile.md5"
	remove="yes"
	source $scripts/shared/put.sh
else
	echo "Unable to create derivative."
	exit 240
fi
