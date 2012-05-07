#!/bin/bash

na="12345"

instruction="{na:'$na',fileSet:'/mnt/sa'}"
CMD="./startup.sh -request.or.fileSet /mnt/sa/12345/josh/mycollection/ -request.or.autoGeneratePIDs uuid -request.or.na 12345 -request.or.label MyCollection -request.or.resolverBaseUrl http://hdl.handle.net/ -request.or.access open -request.or.action add -request.or.contentType image/tiff -request.or.task.name InstructionAutocreate"
echo $CMD
$CMD

