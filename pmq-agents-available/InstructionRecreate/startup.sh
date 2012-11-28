#!/bin/bash
#
# /InstructionRecreate/startup.sh
#
# Creating an instruction based on a fileSet

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
fileSet=$fileSet

mongo $db --quiet --eval "var fileSet='$fileSet'"

exit $?