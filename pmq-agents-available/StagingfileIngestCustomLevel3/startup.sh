#!/bin/bash
#
# StagingfileIngestCustomLevel3/startup.sh
#
# Ingests any custom derivatives of level 3

scripts=$scripts
bucket="level3"
source $scripts/shared/parameters.sh
source $scripts/shared/delete.sh
# Custom derivative material is always ingested
source $scripts/shared/find.derivative.sh

exit $?