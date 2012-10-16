#!/bin/bash
#
# Create or fetch a derivative
# If we can find it, then ingest the derivative into the correct bucket.
#

scripts=$scripts
fileSet=$fileSet
bucket=$bucket
location=$location
db=$db
pid=$pid
derivative=$derivative

echo "Check for existing derivative on fs for master $location"
sourceFile=$(php $scripts/shared/find.derivative.php -f "$fileSet" -l "$location" -b ".$bucket")
if [ -f "$sourceFile" ]; then
        echo "Found custom file: $sourceFile"
        contentType=$(php $scripts/shared/contenttype.php -t $scripts/shared/contenttype.txt -l $sourceFile)
        if [ "$derivative" = "image" ] ; then
            content=$(identify -format "{height:'%h',width:'%w','x-resolution':'%x','y-resolution':'%y'}" $sourceFile)
        fi
        if [ "$derivative" = "audio" ] ; then
            content=$(ffprobe -v quiet -print_format json -show_format -show_streams $sourceFile)
        fi
        if [ "$derivative" = "video" ] ; then
            content=$(ffprobe -v quiet -print_format json -show_format -show_streams $sourceFile)
        fi
    l=$sourceFile
    md5=$(md5sum $l | cut -d ' ' -f 1)
    remove="yes"
    source $scripts/shared/put.sh
fi

echo "No custom derivative found."
exit 245