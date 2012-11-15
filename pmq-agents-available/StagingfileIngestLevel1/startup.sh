#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh

sourceBuckets="master"
targetBucket="level1"

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

derivative=$derivative
file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

echo "We cannot make a derivative of type $derivative"
echo "This is not an error. Just there is no such service."
exit 250