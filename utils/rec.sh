#!/bin/bash

# mongo $2 --quiet --eval "db.level3.files.find({'metadata.pid':{\$regex:'^10622\/30051'}},{_id:0,'metadata.pid':1}).limit(90).forEach(function(d){print(d.metadata.pid)})" > barcodes.txt

echo "<instruction label='barcode grotere lengte x breedte' xmlns='http://objectrepository.org/instruction/1.0/' autoIngestValidInstruction='true' action='upsert' plan='StagingfileIngestLevel3'>"
while read pid
do
    echo "<stagingfile><pid>${pid}</pid></stagingfile>"
done < $1
echo "</instruction>"