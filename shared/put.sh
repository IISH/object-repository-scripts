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
if [ "$derivative" == "image" ] ; then
        content=$(identify -format "{height:'%h',width:'%w','x-resolution':'%x','y-resolution':'%y'}" "$l")
fi
if [ "$derivative" == "audio" ] ; then
        content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
fi
if [ "$derivative" == "video" ] ; then
        content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
fi
if [ ! -z "$content" ] ; then
    content=$(php $scripts/shared/utf8_encode.php -i "$content")
fi
    if [ ! -f "$l" ] ; then
        echo "The file does not exist: $l"
        exit -1
    fi

    # Prepare a key. We suggest a key based on the shard with the fewest documents.
    max=2147483647
    primaries=$primaries
    i=0
    p=0
    for primary in ${primaries[*]}
    do
        c=0
        c=$(timeout 5 mongo $primary/$db --quiet --eval "Math.round(Math.sqrt(db.$bucket.chunks.dataSize()))")
        if [ $c -lt $max ] ; then
           max=$c
           p=$i
         fi
        let i++
    done
    shardKey=$(php $scripts/shared/shardkey.php -s $i -p $p)
    echo "Shardkey: shard $p key $shardKey"

    # Upload our file.
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
        rm $l
        rm $l.md5
        exit 0
    fi
