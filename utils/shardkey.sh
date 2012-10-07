#!/bin/bash

scripts=$scripts

# First create a list of all identifiers per database and per collection.
# Count the numbers per shard. These ought to be exclusive as there is no cardinality for the shardkey 'files_id'
# Calculate the new key per shard: a 32-bit integer: [-2147483648, 2147483647]
# shard 0: [-2147483648, -715827884] = 1431655765
# shard 1: [-715827883, 715827882]   = 1431655765
# shard 2: [715827883, 2147483647]   = 1431655765
for db in or_10622 or_10798 or_10848 or_10851 or_10891
do
    for ns in level3 level2 level1 master
    do
        file=$db.$ns.files.txt
        echo "Collection list $db.$ns.files into $file"
        mongo $db --quiet --eval "db.$ns.files.find({},{_id:1}).forEach(function(d){print(d._id)})" > $file
        chunks=$db.$ns.chunks.txt
        echo "database collection files_id rosaluxemburg0 rosaluxemburg2 rosaluxemburg4" > $chunks
        for files_id in $(cat $file)
        do
            rosaluxemburg0=$(mongo rosaluxemburg0:27018/$db --quiet --eval "db.$ns.chunks.count({files_id:'$files_id'})")
            rosaluxemburg2=$(mongo rosaluxemburg2:27018/$db --quiet --eval "db.$ns.chunks.count({files_id:'$files_id'})")
            rosaluxemburg4=$(mongo rosaluxemburg4:27018/$db --quiet --eval "db.$ns.chunks.count({files_id:'$files_id'})")
            r="$db $ns $files_id $rosaluxemburg0 $rosaluxemburg2 $rosaluxemburg4"
            echo $r
            echo $r >> $chunks
        done
    done
done


