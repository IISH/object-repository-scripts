#!/bin/bash


mkdir "/backup"
/opt/backup_replicaset.sh "or-mongodb-00-2.objectrepository.org:27018" "localhost:27018" "or_10622" "master" "/data/backup" "or@10.24.86.68:/data" "yes" > "/opt/backup.${HOSTNAME}.log"
