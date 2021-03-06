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
    contentType=$(php $scripts/shared/extension2contenttype.php -t $scripts/shared/contenttype.txt -l "$sourceFile")
    l=$sourceFile
    md5=$(md5sum "$l" | cut -d ' ' -f 1)
    remove="yes"
    source $scripts/shared/put.sh
fi

echo "No custom derivative found"
exit 245