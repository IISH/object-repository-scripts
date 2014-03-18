#!/bin/bash
#
# list_metadata
#
# Collect from a list all known metadata.


BUCKETS="master level1 level2 level3"

function metadata() {

    header="pid"
    for b in $BUCKETS
    do
         header="${header},${b}"
    done
    echo $header


    while read pid
    do
        record=$pid
        normalize_pid=${pid/\//\\\/}
        for b in $BUCKETS
        do
            query="function v(arg){if ( arg == undefined ) return '?' ; else return arg};var md=db['${b}.files'].findOne({'metadata.pid':'${normalize_pid}'}, {'metadata.content':1}); if ( md && md.metadata && md.metadata.content ) print(v(md.metadata.content.height) + ' x ' + v(md.metadata.content.width) + ' (' + v(md.metadata.content['y-resolution']) + ' x ' + v(md.metadata.content['x-resolution']) + ')'); else print('');"
            md=$(mongo $DB --quiet --eval "$query")
            record="${record},${md}"
        done
        echo $record
    done < $list_with_pids
}


function main() {

    DB=$1
    if [ -z "$DB" ] ; then
        echo "No database set. Assuming test."
        DB=test
    fi

    list_with_pids=$2
    if [ ! -f $list_with_pids ] ; then
        echo "File not found: ${list_with_pids}"
        exit -1
    fi

    metadata

}

main "$@"
