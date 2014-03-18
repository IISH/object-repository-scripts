#!/bin/bash
#
# list_usage
#
# Count user statistics from pids in a given list


BUCKETS="master level1 level2 level3"

function metadata() {

    header="pid"
    for b in $BUCKETS
    do
         header="${header},${b}"
    done
    echo $header

    # Only get 200

    while read pid
    do
        record=$pid
        normalize_pid=${pid/\//\\\/}
        for b in $BUCKETS
        do
            # Find all bucket and pid combinations that are valid downloads
            url="/${b}/${pid}"
            echo $url
            count=$(grep -E "/${b}/${pid}" $usage_file | grep -E '\s200\s' | grep -v '195.169.122.' | grep -v '195.169.123.' | grep -v '195.169.88.' | wc -l)
            record="${record},${count}"
        done
        echo $record
    done < $list_with_pids
}


function main() {

    list_with_pids=$1
    if [ ! -f $list_with_pids ] ; then
        echo "File not found: ${list_with_pids}"
        exit -1
    fi

    usage_file=$2
    if [ ! -f $usage_file ] ; then
        echo "File not found: ${usage_file}"
        exit -1
    fi

    metadata

}

main "$@"
