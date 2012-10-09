#!/bin/bash
#
# /shared/put.sh
#
# Adds a file into the database
#

scripts=$scripts
source $scripts/shared/parameters.sh
access=$access
bucket=$bucket
content=$content
contentType=$contentType
db=$db
fileSet=$fileSet
host=$host
l="$l"
label="$label"
length=$length
md5=$md5
na=$na
orfiles=$orfiles
pid="$pid"
lid="$lid"
resolverBaseUrl="$resolverBaseUrl"
identifier=$identifier
hostname=$hostname

    if [ ! -f "$l" ] ; then
        echo "The file does not exist: $l"
        exit -1
    fi

    # Upload our file.
    # Legacy issue... we migrate from the dataType: from a string identifier to a integer 32 bit
    shardkeyDatatype="int"
    if [ "$db" == "or_10622" ]; then
        shardkeyDatatype="string"
    fi
    java -DshardkeyDatatype=$shardkeyDatatype -jar $orfiles -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -s "" -t $contentType -M Put
    rc=$?

    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    mongo $db --quiet --eval "\
    var access='$access'; \
    var content=$content; \
    var filesDB='$db'; \
    var na='$na'; \
    var fileSet='$fileSet'; \
    var label='$label'; \
    var length=$length; \
    var md5='$md5'; \
    var ns='$bucket'; \
    var pid='$pid'; \
    var lid='$lid'; \
    var resolverBaseUrl='$resolverBaseUrl'; \
    ''" $scripts/shared/put.js

    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

        mongo $db --quiet --eval "\
        var ns='$bucket'; \
        var md5='$md5'; \
        var length=$length; \
        var pid = '$pid'; \
        ''" $scripts/shared/integrity.js

    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    # Add to the statistics
    mongo $db --quiet --eval "var pid = '$pid';var ns='$bucket';" $scripts/shared/statistics.js

    remove=$remove
    if [ "$remove" == "yes" ] ; then
        # Now verify if a file with the given length and md5 exists so we can remove it from the fs
            rm $l
            rm $l.md5
            exit 0
    fi
