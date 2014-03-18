#!/bin/bash
#
# dropsafe
#
# Prevent major data loss on Secondary Delayed replicaset members, due to database drop command or remove queries.
#
# Query self (the delayed replica member) and the Primary.
# Detect if the percentage of records is lower than the allowed primary to secondary ratio.
# This ratio is expressed as a percentage.
#
# If the measurement is lower than the percentage, shut down and user lock the database.
#
# E.g.:
# safety_line_percent=90 ( percent )
#
# Primary has 9100 records in it's collection.
# Secondary has 10000 records in it's collection.
# ( 1 + 9100 * 100 ) / ( 1 + 10000 ) = 90 % => no action
#
# Primary has 5000 records in it's collection.
# Secondary has 10000 records in it's collection.
# ( 1 + 5000 * 100 ) / ( 1 + 10000 ) = 49 % => shutdown command
#
#
# Arguments:
#   $1 = safety percentage ( default 90 )
#
# Environment:
#  dbs defined as a string of spaced separated mongodb names.
#
# Author: Lucien van Wouw <lwo@iisg.nl>

DATESTAMP=$(date)
LOG=/opt/dropsafe.log
SAFETY_LINE_PERCENT=90
COLLECTIONS="level3 level2 level1 master"
BUCKETS="files chunks"
DBS=$dbs


function drop_safe() {

    count_primary   =?
    count_secondary =?
    ratio           =?

    replicaset_primary=$(mongo test --eval "rs.status().members.forEach(function(d){ if ( d.state == 1 ) print(d.name)})")
    rc=$?
    if [[ $rc != 0 ]] || [[ -z "$replicaset_primary" ]]; then
        echo "${DATESTAMP}: Unable to get a replica status" >> $LOG
    else
        # Create site usage
        for db in ${DBS[*]}
        do
            for b in $COLLECTIONS
            do
                for c in $BUCKETS
                do
                    collection=$b.$c
                    f=/opt/$db.$collection
                    query="db['${collection}'].count()"

                    # Get the count from the remote primary
                    count_primary=$(timeout 10 mongo $replicaset_primary/$db --eval ${query})
                    rc=$?
                    if [[ $rc != 0 ]] || [[ -z "$count_primary" ]]; then
                        echo "${DATESTAMP} Error ${rc} P:error for ${f}" >> $LOG
                    else
                        # Get the count from this secondary
                        count_secondary=$(timeout 10 mongo $db --eval "rs.slaveOk(); ${query}")
                        rc=$?
                        if [[ $rc != 0 ]] || [[ -z "$count_secondary" ]]; then
                            echo "${DATESTAMP} Error ${rc} P:${count_primary} S:error for ${f}" >> $LOG
                        fi
                    fi

                    if [[ $rc == 0 ]] ; then
                        # calculate the deviation
                        ratio=$(echo "scale=0; (100*(${count_primary})+1)/(${count_secondary}+1)" | bc)

                        if [[ $ratio < $safety_line_percent ]]; then
                            echo "${DATESTAMP} Failsafe trickered as ratio is below the safety percentage" >> $LOG
                            service mongodb stop
                            sleep 60
                            chmod -R 400 /data/mongodb/
                        fi
                    fi

                    #  Log all
                    echo "${DATESTAMP} P:${count_primary} S:{count_secondary} safety line: ${safety_line_percent} measured ratio:${ratio}" >> $LOG

                done
            done
        done
    fi

    exit 0
}

function main() {

    # Any value lower than this should start a shutdown
    safety_line_percent="$1"
    if [ -z "$safety_line_percent" ] ; then
        echo "${DATESTAMP}: Command variable safety_line_percent is not defined. Asumming ${SAFETY_LINE_PERCENT}" >> $LOG
        safety_line_percent=$SAFETY_LINE_PERCENT
    fi

    if [ -z $DBS ] ; then
        echo "${DATESTAMP}: Environment variable dbs is not defined. Asumming test" >> $LOG
        DBS=test
    fi

    drop_safe
}

main "$@"