#!/bin/bash

file="$1"
mongo "$2" --quiet --eval "db.level3.files.find({'metadata.pid':{\$regex:'^10622\/30051'}},{_id:0,'metadata.pid':1, 'metadata.access':1}).forEach(function(d){print(d.metadata.pid + ' ' + d.metadata.access)})" > "$file"

echo "<instruction \
    label='barcode grotere lengte x breedte' \
    xmlns='http://objectrepository.org/instruction/1.0/' \
    autoIngestValidInstruction='true' \
    action='upsert' \
    contentType='image/tiff' \
    plan='StagingfileIngestLevel3' \
    replaceExistingDerivatives='true'>"
while read line
do
    read pid access <<< "$line"
    echo "<stagingfile><access>${access}</access><pid>${pid}</pid></stagingfile>"
done < "$file"
echo "</instruction>"