#!/bin/bash
#
# StagingfileIngestCustomLevel1/startup.sh
#
# Ingests any custom derivatives of level 1

scripts=$scripts
bucket="level1"
source $scripts/shared/parameters.sh
source $scripts/shared/delete.sh
# Custom derivative material is always ingested
source $scripts/shared/find.derivative.sh

exit $?