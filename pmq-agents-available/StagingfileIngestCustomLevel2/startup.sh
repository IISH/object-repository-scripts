#!/bin/bash
#
# StagingfileIngestCustomLevel2/startup.sh
#
# Ingests any custom derivatives of level 2

scripts=$scripts
bucket="level2"
source $scripts/shared/parameters.sh
action=$action
source $scripts/shared/secondaries.sh

if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

source $scripts/shared/find.derivative.sh

exit $?