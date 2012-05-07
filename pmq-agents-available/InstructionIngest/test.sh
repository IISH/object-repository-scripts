#!/bin/bash

CMD="./startup.sh -request.or.fileSet /mnt/sa/10000/folder_of_cpuser/test-collection/ -request.or.autoGeneratePIDs uuid -request.or.na 12345 -request.or.label MyCollection -request.or.resolverBaseUrl http://hdl.handle.net/ -request.or.access open -request.or.contentType image/jpg -request.or.task.name InstructionIngest"
echo $CMD
$CMD

