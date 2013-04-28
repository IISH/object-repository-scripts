#!/bin/bash

for db in $dbs
do
    for ns in level3 level2 level1 master
    do
            echo "Validation on $db.$ns"
            file=chunk.check.$db.$ns.sh
            mongo $db --eval "db.$ns.files.find({},{_id:1}).forEach(function(d){print('./chunk.check.sh $db $ns '+d._id)})" > $file
            chmod 744 $file
    done
done

for db in $dbs
do
    for ns in level3 level2 level1 master
    do
            source $file
    done
done

