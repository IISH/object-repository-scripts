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
lid="$lid"
resolverBaseUrl="$resolverBaseUrl"

    if [ ! -f "$l" ] ; then
        echo "The file does not exist: $l"
        exit -1
    fi

    # Upload our file.
    # The PUT will fail when md5 and length compound key is unique.
    echo "-c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -t $contentType -M Put"
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

    remove=$remove
    if [ $remove ] ; then
        # Now verify if a file with the given length and md5 exists so we can remove it from the fs
        query="{md5:'$md5',length:$length}"
        mustHave=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.pid")
        if [ "$mustHave" == "$pid" ] ; then
            rm -f $l
            rm -f $l.md5
            exit 0
        else
            echo "Error. No file found with $query"
            echo "Expected  $pid"
            echo "Was       $mustHave"
            exit -1
        fi
    fi
