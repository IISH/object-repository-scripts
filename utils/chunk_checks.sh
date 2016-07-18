#!/bin/bash
#
# For each host start the chunk procedure

replicaset=$1
host=mongo or-mongodb-$replicaset-2.objectrepository.org
db=or_10622

mongo $host:27018/$db --eval "var lower=db.master.chunks.find({},{files_id:1}).sort({files_id:1}).limit(1); print(lower[0].files_id)"