#!/bin/bash

# assign pidType to all
# remove empty objid fields

for db in ${dbs[*]}
do
    for c in master level1 level2 level3
    do
        mongo $db --eval "db.$c.files.update({'metadata.objid':''},{\$unset:{'metadata.objid':1}}, false, true);db.runCommand({getlasterror:1, w:"majority"})"
        mongo $db --eval "db.$c.files.update({'metadata.objid':null},{\$unset:{'metadata.objid':1}}, false, true);db.runCommand({getlasterror:1, w:"majority"})"
        mongo $db --eval "db.$c.files.update({},{\$set:{'metadata.pidType':'or'}}, false, true);db.runCommand({getlasterror:1, w:"majority"})"
    done
done