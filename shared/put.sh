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
host=$host
l="$l"
label="$label"
length=$length
md5=$md5
na=$na
orfiles=$orfiles
pid="$pid"
resolverBaseUrl="$resolverBaseUrl"

    if [ ! -f "$l" ] ; then
        echo "The file does not exist: $l"
        exit -1
    fi

    # Upload our file.
    # The PUT will fail when md5 and length compound key is unique.
    java -jar $orfiles -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -t $contentType -M Put

    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    mongo $db --quiet --eval "\
    var access='$access'; \
    var content=$content; \
    var filesDB='$db'; \
    var na='$na'; \
    var label='$label'; \
    var length=$length; \
    var md5='$md5'; \
    var ns='$bucket'; \
    var pid='$pid'; \
    var resolverBaseUrl='$resolverBaseUrl'; \
    ''" $scripts/shared/put.js

    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi
