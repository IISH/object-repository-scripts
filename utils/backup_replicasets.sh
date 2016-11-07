#!/bin/bash


mkdir "/backup"
/opt/backup_replicaset.sh "or-mongodb-00-2.objectrepository.org:27018" "localhost:27018" "or_10622" "master" "/data/backup" "mongodb@10.24.86.68:/data" > "/backup/backup.${HOSTNAME}.log"
