#!/bin/bash

for db in  or_10662 or_10796 or_10848 or_10851 or_10891
do
    for ns in level3 level2 level1 master
    do
            echo "Validation on $db.$ns"
            file=chunk.checks.$db.$ns.sh
            mongo $db --eval "db.$ns.files.find({},{_id:1}).forEach(function(d){print('./chunk.check.sh $db $ns '+d._id)})" > $file
            chmod 744 $file
            source $file
    done
done

