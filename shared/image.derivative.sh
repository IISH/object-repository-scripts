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
targetBucket=$targetBucket
tmp=$tmp
targetFile=$tmp/$md5.$targetBucket
sourceFileExtension=$sourceFileExtension

for bucket in $sourceBuckets
do
    sourceFile=$tmp/$md5.$bucket.$sourceFileExtension
    if [ -f $sourceFile ]; then
	    echo "Using existing cached file on $sourceFile"
	    break
    else
	    source $scripts/shared/get.sh
	    if [ -f $sourceFile ] ; then
	        echo "Using existing cached file on $sourceFile"
	        break
	    fi
    fi
done

# Run the convert script to create derivative.
if [ -f $sourceFile ]; then
	echo "Creating derivative from $sourceFile"
	cmd=`php $scripts/shared/image.derivative.php -i $sourceFile -l $targetBucket -d $db -p $pid -s $scripts/shared/content.js -o $targetFile `
	echo "cmd=$cmd"
	convert $cmd
else
	echo "Could not find sourceFile: $sourceFile"
fi

# The derivative script has added a jpg extension to the targetFile, which we take over here.
targetFile=$targetFile$.jpg
if [ -f $targetFile ]; then
	$scripts/shared/put.sh $@ contentType image/jpeg -bucket $targetBucket -l $targetFile
fi

if [ -f $sourceFile ]; then
	rm -f $sourceFile
fi


