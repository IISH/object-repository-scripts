#!/bin/bash
#
# StagingFileIngestConcordance/startup.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document

scripts=$scripts
validation=$validation

source $scripts/shared/parameters.sh
fileSet=$fileSet
na=$na

//java -cp $validation org.objectrepository.validation.ConcordanceMain -dataDir /mnt/sa/12345/testuser2/ARCH00040/ -prefix ARCH00040 -pidprefix 10622

prefix=$(dirname $fileSet)
java -cp $validation org.objectrepository.validation.ConcordanceMain -dataDir $fileSet -prefix $prefix -pidprefix $na