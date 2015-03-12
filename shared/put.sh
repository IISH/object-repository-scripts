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
derivative=$derivative
l="$l"

if [ ! -f "$l" ] ; then
    echo "The file does not exist: $l"
    exit -1
fi

if [ "$derivative" == "image" ] ; then
    # ToDo: do not use format, but parse the entire identify response to json
    content=$(identify -format "{height:'%h',width:'%w','x-resolution':'%x','y-resolution':'%y'}" "$l")
fi
if [ "$derivative" == "audio" ] ; then
    content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
fi
if [ "$derivative" == "video" ] ; then
    content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
fi
if [ "$contentType" == "text/xml" ] || [ "$contentType" == "application/xml" ] ; then
    content=$(php $scripts/shared/identify_xmlns.php -l "$l")
fi
if [[ ${content:0:1} == "{" ]]; then
    content=$(php $scripts/shared/utf8_encode.php -i "$content")
else
    # invalid response... no json
    content="null"
fi
    # Prepare a key. We suggest a key based on the shard with the fewest documents.
    shardKey=0
    shardKey=$(mongo $db --quiet --eval "var lib_dir='${scripts}/shared/'; var bucket='${bucket}'; var db_shard='${DB_SHARD}'; var file_size=NumberLong('${length}');" $scripts/shared/shardkey.2a.js)
    is_numeric=$(php -r "print(is_numeric('$shardKey'));")
    if [ -z "$is_numeric" ] ; then
        shardKey=0
    fi
    if [[ $shardKey == 0 ]]; then
        echo "Could not retrieve a shardkey from shardkey.2a.js"
        exit -1
    fi

    # Upload our file. For masters we increase the write concern
    # REPLICAS_SAFE = Wait for at least 2 servers for the write operation
    echo "Shardkey: $shardKey"
    mongo $DB_SHARD/shard --quiet --eval "var shardkey=$shardkey; var file_size=NumberLong('${length}');" $scripts/shared/reserve_storage.js
    writeConcern="REPLICAS_SAFE"
    java -DWriteConcern=$writeConcern -jar $orfiles -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -s $shardKey -t $contentType -M Put
    rc=$?
    mongo $DB_SHARD/shard --quiet --eval "var shardkey=$shardkey; var file_size=NumberLong('-${length}');" $scripts/shared/reserve_storage.js

    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

# This may fail because of a corrupt content value.
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
    var l='$instruction_location'; \
    var resolverBaseUrl='$resolverBaseUrl'; \
    var contentType='$contentType'; \
    var seq=Number('0$seq'); \
    var objid='$objid'; \
    var embargo='$embargo'; \
    var embargoAccess='$embargoAccess'; \
    " $scripts/shared/put.js

# toDo: make sure the content type is a proper json field... so we can remove this quick fix.
rc=$?
if [[ $rc != 0 ]] ; then
    mongo $db --quiet --eval "\
        var access='$access'; \
        var content=null; \
        var filesDB='$db'; \
        var na='$na'; \
        var fileSet='$fileSet'; \
        var label='$label'; \
        var length=$length; \
        var md5='$md5'; \
        var ns='$bucket'; \
        var pid='$pid'; \
        var lid='$lid'; \
        var l='$instruction_location'; \
        var resolverBaseUrl='$resolverBaseUrl'; \
        var contentType='$contentType'; \
        var seq=Number('0$seq'); \
        var objid='$objid'; \
        var embargo='$embargo'; \
        var embargoAccess='$embargoAccess'; \
        " $scripts/shared/put.js
    rc=$?
    if [[ $rc != 0 ]] ; then
        echo  "Failed to save metadata. Even tried twice."
        exit $rc
    fi
fi

    # With the fs... this check is really not necessary then using REPLICAS_SAFE
    mongo $db --quiet --eval "\
       var ns='$bucket'; \
       var md5='$md5'; \
       var pid = '$pid'; \
       var paranoid = false ; \
       " $scripts/shared/integrity.js

    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    # Add to the statistics
    # mongo $db --quiet --eval "var pid = '$pid';var ns='$bucket';" $scripts/shared/statistics.js
    mongo $db --quiet --eval "var pid='$pid';var ns='$bucket'" $scripts/shared/vfs.js

    remove=$remove
    if [ "$remove" == "yes" ] ; then
        rm "$l"
        rm "$l.md5"
        exit 0
    fi
