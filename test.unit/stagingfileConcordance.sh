#!/bin/bash

scripts=$scripts
na=12345
fileSet=/mnt/sa/$na/testuser2/ARCH00040
pid="10622/ARCH00040"

$scripts/pmq-agents-available/StagingfileConcordance/startup.sh -na $na -fileSet $fileSet -pid $pid
