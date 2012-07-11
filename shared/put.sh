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

    if [ ! -f "$l" ] ; then
        echo "The file does not exist: $l"
        exit -1
    fi

empty="null"
shardprefix=$empty
while [ "$shardprefix"=="$empty" ] ;
do
    shardprefix=$(mongo sa --quiet --eval "var doc=db.getCollection('shardprefix').findAndModify( { \
        query:{identifier:{\$exists:false}}, \
        update:{\$set:{identifier:'$identifier'}}, \
        upsert:false, \
        fields:{_id:1 }}); \
        ( doc == null ) ? null : doc._id \
    ")
    if [ "$shardprefix"=="$empty" ] ; then
        sleep 5
     fi
done

    # Upload our file.
	java -jar $orfiles -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -s "$shardprefix" -t $contentType -M Put

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

    mongo sa --quiet --eval "db.shardprefix.update({identifier:'\$identifier'}, {\$unset:{identifier:1}}, true, true)"

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

    remove=$remove
    if [ "$remove" == "yes" ] ; then
        # Now verify if a file with the given length and md5 exists so we can remove it from the fs
            rm $l
            rm $l.md5
            exit 0
    fi
