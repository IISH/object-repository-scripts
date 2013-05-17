#!/bin/bash
#
# StagingFileIngestConcordance/ingest.pids.sh
#
# Declare and bind our ObjId PIDs
#
scripts=$scripts
validation=$validation
metsmaker=$metsmaker
lftpUser=$lftpUser
lftpPassword=$lftpPassword
fileSet=$fileSet
na=$na
archiveID=$archiveID
log=$log
cf=$cf
ftpScript=$ftpScript
fileSetMets=$fileSetMets


echo "Declare pids...">>$log

# Example line is
# 1,1,/ARCH00518/Tiff/1/1_0005.tif,/ARCH00518/Jpeg/1/1_0005.jpg,5,10622/A3EF7419-A1D8-4698-8369-F62ADAEC703E
while read line
do
    while IFS=, read objnr ID master jpeg volgnr PID; do
        if [[ $volgnr == 1 ]]; then
            source $scripts/pmq-agents-available/StagingfileConcordance/upsert.sh
        fi
    done
done < $cf

echo "Done file pid declarations.">>$log