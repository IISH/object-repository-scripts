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
if [[ ${content:0:1} == "{" ]]; then
    content=$(php $scripts/shared/utf8_encode.php -i "$content")
else
    # invalid response... no json
    content="null"
fi
    # Prepare a key. We suggest a key based on the shard with the fewest documents.
    shards=$shards
    shardKey=$(timeout 60 mongo $db --quiet --eval "var bucket='$bucket'; var shards=$shards" $scripts/shared/shardkey.js)
    is_numeric=$(php -r "print(is_numeric('$shardKey'));")
    if [ -z "$is_numeric" ] ; then
        shardKey=0
    fi
    if [[ $shardKey == 0 ]]; then
        echo "Could not retrieve a shardkey. Primaries may be down."
        exit -1
    fi

    # Upload our file.
    echo "Shardkey: $shardKey"
    java -jar $orfiles -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -s $shardKey -t $contentType -M Put
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
    var contentType='$contentType'; \
    " $scripts/shared/put.js


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
    # mongo $db --quiet --eval "var pid = '$pid';var ns='$bucket';" $scripts/shared/statistics.js

    remove=$remove
    if [ "$remove" == "yes" ] ; then
        rm "$l"
        rm "$l.md5"
        exit 0
    fi
