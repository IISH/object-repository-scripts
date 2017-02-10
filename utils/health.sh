#!/bin/bash
#
# Check the health and expected state of the node. See if we can write to the disk.


NOW=`date`
DIR="/opt/health"
mkdir -p $DIR

OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

PRIMARY=1
SECONDARY=2

function state() {
    arg=$1
    case $arg in
        $PRIMARY)
            echo "Primary"
         ;;
         $SECONDARY)
             echo "Secondary"
         ;;
         *)
             echo "Unknown"
         ;;
     esac
}

function status() {
    arg=$1
    case $arg in
         $CRITICAL)
             echo "critical"
         ;;
         $OK)
            echo "ok"
         ;;
         $WARNING)
            echo "warning"
         ;;
         *)
             echo "unknown"
         ;;
     esac
}

function style() {
    arg=$1
    case $arg in
         $CRITICAL)
             echo "critical"
         ;;
         $OK)
            echo "ok"
         ;;
         $WARNING)
            echo "warning"
         ;;
         *)
             echo "unknown"
         ;;
     esac
}

function main() {

    echo "<html>"
    echo "<head>"
    echo "<style type='text/css'>"
    echo ".critical {background-color: white; color: red;}"
    echo ".ok {background-color: white; color: green;}"
    echo ".unknown {background-color: white; color: red;}"
    echo ".warning {background-color: white; color: red;}"
    echo "</style>"
    echo "</head>"
    echo "<body>"
    echo "<h1>${NOW}</h1>"
    echo "<table border='1'>"
    echo "<th>host</th><th>status</th>"


    for n in {00..26}
    do
        EXPECTED_STATE=0
        for m in 0 1 2
        do
            case $m in
                0)
                    EXPECTED_STATE=$SECONDARY
                ;;
                1)
                    EXPECTED_STATE=$SECONDARY
                ;;
                2)
                    EXPECTED_STATE=$PRIMARY
                ;;
            esac

            host="or-mongodb-${n}-${m}.objectrepository.org:27018/test"
            state=$(mongo $host --quiet --eval "var state=${UNKNOWN}; rs.status().members.forEach(function(d){if (d.self) {if (d.health == 1) {state=(d.state==${EXPECTED_STATE}) ? ${OK}: ${WARNING};if (d.state==$PRIMARY){db.test.save({});db.test.remove()}} else {state=${CRITICAL}}}});print(state)")
            rc=$?
            if [[ "$rc" != 0 ]]
            then
                state=$UNKNOWN
            fi

            label_status=$(state $state)
            label_expected_state=$(state $EXPECTED_STATE)
            style=$(style $state)

            if [[ $state == $OK ]]
            then
                echo "<tr><td>${host}</td><td class='${style}'>${label_expected_state}</td></tr>"
            else

                echo "<tr><td>${host}</td><td class='${style}'>expected ${label_expected_state} but got ${label_status}</td></tr>"
            fi
        done
    done


    echo "</table>"
    echo "</body>"
    echo "</html>"
}


main