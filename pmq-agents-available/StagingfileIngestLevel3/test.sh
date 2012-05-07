#!/bin/bash

fileSet="/mnt/sa/12345/cp12345/2012-02-25"
location="/2012-02-25/30051000685906.tif"
pid="12345/30051000685906"
./startup.sh -request.or.na 12345 -request.or.file.pid $pid -request.or.label label -request.or.resolverBaseUrl http://hdl.handle.net/ -request.or.access open -request.or.file.location $location -request.or.file.md5 4e4836baa12ac0b2cf085e6995050846 -request.or.file.contentType image/tiff -request.or.fileSet $fileSet

