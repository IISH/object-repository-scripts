#!/bin/bash

fileSet="/mnt/sa/12345/cp12345/2012-02-25"
location="/2012-02-25/30051000685906.tif"
pid="12345/30051000685906"
./startup.sh -request.instruction.na 12345 -request.instruction.file.pid $pid -request.instruction.label label -request.instruction.resolverBaseUrl http://hdl.handle.net/ -request.instruction.access open -request.instruction.file.location $location -request.instruction.file.md5 4e4836baa12ac0b2cf085e6995050846 -request.instruction.file.contentType image/tiff -request.instruction.fileSet $fileSet

