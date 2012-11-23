#!/bin/bash
#
# StagingfileIngestCustomLevel1/startup.sh
#
# Ingests any custom derivatives of level 1

scripts=$scripts
bucket="level1"
source $scripts/shared/parameters.sh
source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh
source $scripts/shared/find.derivative.sh

exit $?