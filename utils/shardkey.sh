#!/bin/bash

scripts=$scripts

for db in or_10622 or_10798 or_10848 or_10851 or_10891
do
    for ns in level3 level2 level1 master
    do
        count=0
        for shard in "0" "2" "4"
        do
            echo "Collection $db.$ns"
            mongo rosaluxemburg$shard $db --quiet --eval "var shard='$shard';var ns='$ns';var count=$count;var index=0;" $scripts/utils/shardkey.sh
            inc=$(mongo $db --quiet --eval "db.$ns.files.count()")
            count=$(count+$inc)
        done
    done
done