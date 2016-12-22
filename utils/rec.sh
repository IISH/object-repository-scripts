#!/bin/bash


echo "<instruction xmlns='http://objectrepository.org/instruction/1.0/' autoIngestValidInstruction='true' action='upsert' plan='StagingfileIngestLevel3'>"
while read pid
do
    echo "<stagingfile><pid>${pid}</pid></stagingfile>"
done < $1
echo "</instruction>"