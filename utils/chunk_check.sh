#!/bin/bash

db=$1
for c in level3.files level2.files level1.files master.files
do
        echo "Validation on $db.$c"
        mongo $db --eval "var collection='$c'" /usr/bin/object-repository/scripts/utils/chunk_check.js > $db.$c.txt
done
