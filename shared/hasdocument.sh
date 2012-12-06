#!/bin/bash
#
# hasdocument.sh
#
# Stop processing if we find a document already.

db=$db
bucket=$bucket
pid=$pid
scripts=$scripts
replaceExistingDerivatives=$replaceExistingDerivatives

if [ "$replaceExistingDerivatives" == "true" ]; then
    echo "Replace existing derivatives"
else
    hasdocument=$(mongo $db --quiet --eval "var bucket='$bucket';var pid='$pid'" $scripts/shared/hasdocument.js)
    if [ "$hasdocument" == "true" ] ; then
        echo "The file in $bucket with $pid exists. Hence we stop processing here."
        exit 245
    fi
fi