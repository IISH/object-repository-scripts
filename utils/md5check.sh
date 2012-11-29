#!/bin/bash
#
# md5check.sh
#
# Protection against file degradation: bits changing over time on fs.
#
# Service that randomly selects gridFS chunks from the collection and recalculates their md5 value.
# Each chunk has a md5 field.
#
# Procedure: assume there is one primary and one secondary
# 1. List all primaries: shards
# 2. for each primary iterate though the chunks
# 3. for each chunk recalculate the md5
# 4. obtain the associate chunk from the secondary by ObjectId
# 5. when the chunks match continue with the next chunk
# 6. if one out of the two hosts mismatch: take the chunk that has a match and update the faulty host: primary or secondary
# 7. if both mismatch print the problem chunk.

shards=$shards
db=$db
bucket=master

for host in a b c
do
    mongo $host/$db --quiet --eval "var count=db.$bucket.files.count(); /
        var index=Math.floor(Math.random()*count); /
        var doc=db.$bucket.files.find({},{_id:1}).skip(index).limit(1); /
        db.$bucket.chunks.find( { files_id : doc_id }, {_id:1, md5:1 } ).forEach(function(d){ /
        print(d._id,
        }); /
    "

done