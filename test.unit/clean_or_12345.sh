#!/bin/bash

for bucket in "master" "level1" "level2" "level3"
    do
        mongo or_12345 --quiet --eval "db.getCollection('$bucket.files').remove()"
        mongo or_12345 --quiet --eval "db.getCollection('$bucket.chunks').remove()"
done
