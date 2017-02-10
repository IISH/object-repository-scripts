#!/bin/bash

#mongo $1 --quiet --eval "db.level3.files.find({'metadata.pid':{\$regex:'^10622\/30051'},'metadata.lastUploadDate':{\$lt:ISODate('2017-01-15')}},{_id:0,'metadata.pid':1,'metadata.access':1}).forEach(function(d){print(d.metadata.pid+' '+d.metadata.access)})" > barcodes.txt

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
    read pid access <<< $line
    echo "<stagingfile><pid>${pid}</pid></stagingfile>"
done < $1
echo "</instruction>"