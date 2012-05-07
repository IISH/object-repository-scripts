#!/bin/bash
#
# /InstructionUpload/startup.sh

scripts=$scripts
source $scripts/shared/instruction.sh
fileSet=$fileSet

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

rm $fileSet/instruction.xml

exit 0
