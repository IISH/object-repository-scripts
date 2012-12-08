#!/bin/bash
#
# StagingfileIngestCustomLevel2/startup.sh
#
# Ingests any custom derivatives of level 2

scripts=$scripts
bucket="level2"
source $scripts/shared/parameters.sh
source $scripts/shared/delete.sh
# Custom derivative material is always ingested
source $scripts/shared/find.derivative.sh

exit $?