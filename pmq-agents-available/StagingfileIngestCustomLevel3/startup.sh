#!/bin/bash
#
# StagingfileIngestCustomLevel3/startup.sh
#
# Ingests any custom derivatives of level 3

scripts=$scripts
bucket="level3"
source $scripts/shared/parameters.sh
action=$action
source $scripts/shared/secondaries.sh

if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

source $scripts/shared/find.derivative.sh

exit $?