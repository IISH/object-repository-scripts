#!/bin/bash
#
# StagingfileIngestCustomLevel1/startup.sh
#
# Ingests any custom derivatives of the level1, level2 and level3 sort.

scripts=$scripts
bucket="level1"
source $scripts/shared/parameters.sh
action=$action
source $scripts/shared/primary.sh

if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

source $scripts/shared/find.derivative.sh

exit $?