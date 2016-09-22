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
orfiles=$(cwp "$orfiles")
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
l=$(cwp "$l")

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
    enc=$(cwp "$scripts/shared/utf8_encode.php")
    content=$(php "$enc" -i "$content")
else
    # invalid response... no json
    content="null"
fi

# Prepare a key. We suggest a key based on the shard with the fewest documents.
shardKey=0
shardKey=$(mongo $db --quiet --eval "var bucket='${bucket}'; var db_shard='${DB_SHARD}'; var file_size=NumberLong('${length}');" $(cwp "$scripts/shared/shardkey.2a.js") | tr -d '\r\n')
is_numeric=$(php -r "print(is_numeric('$shardKey'));")
if [ "$is_numeric" != "1" ] ; then
    echo "Invalid shardKey value: ${shardKey}"
    shardKey=0
fi

if [[ $shardKey == 0 ]]; then
    echo "Could not retrieve a shardkey from shardkey.2a.js"
    exit -1
fi

# Upload our file.
# REPLICAS_SAFE = Wait for at least 2 servers for the write operation
echo "Shardkey: $shardKey"
mongo $DB_SHARD/shard --quiet --eval "var shardkey=${shardKey}; var file_size=NumberLong('${length}');" $(cwp "$scripts/shared/reserve_storage.js")
writeConcern="REPLICAS_SAFE"
java -DWriteConcern=$writeConcern -jar "$orfiles" -c files -l "$l" -m $md5 -b $bucket -h $host -d "$db" -a "$pid" -s $shardKey -t $contentType -M Put
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Removing the reserved key, because we had a PUT failure."
    mongo $db --quiet --eval "db.${bucket}.files.remove({'metadata.pid':${shardKey}})"
    mongo $DB_SHARD/shard --quiet --eval "var shardkey=${shardKey}; var file_size=NumberLong('-${length}');" $(cwp "$scripts/shared/reserve_storage.js")
    exit $rc
fi

mongo $DB_SHARD/shard --quiet --eval "var shardkey=${shardKey}; var file_size=NumberLong('-${length}');" $(cwp "$scripts/shared/reserve_storage.js")

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
    " $(cwp "$scripts/shared/put.js")

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
        " $(cwp "$scripts/shared/put.js")
    rc=$?
    if [[ $rc != 0 ]] ; then
        echo  "Failed to save metadata. Even tried twice."
        exit $rc
    fi
fi

# Now download the file again and see if the checksum is as we expect it to be.
# We do this only for the master.
validate_file="$validate_file"
if [ "$validate_file" == "yes" ]
then
    archiveID=$(basename "$fileSet")
    workdir="$(dirname "$fileSet")/.work/${archiveID}"
    if [ ! -d "$workdir" ]
    then
        mkdir -p "$workdir"
    fi
    md5_check_file="${workdir}/${md5}.bin"
    java -jar "$orfiles" -M Get -l "$md5_check_file" -host "$host" -d "$db" -b master -a "$pid" -m ""
    md5_check=$(md5sum "$md5_check_file" | cut -d ' ' -f 1)
    rm "$md5_check_file"
    if [ "$md5" == "$md5_check" ]
    then
        echo "md5 checksum ok"
    else
        echo "md5 mismatch then comparing the file with a checkout version."
        echo "Expect ${md5} but got ${md5_check}  ${md5_check_file}"
        mongo "$db" --quiet --eval "db.$bucket.files.remove({_id:$shardKey})"
        mongo "$db" --quiet --eval "db.$bucket.chunks.remove({files_id:$shardKey})"
        mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'; var del=true;" $(cwp "$scripts/shared/vfs.js")
        exit 1
    fi
fi


# Remove the derivatives.
remove_derivatives="$remove_derivatives"
if [ "$remove_derivatives" == "yes" ]
then
    for b in level3 level2 level1
    do
        files_id=$(mongo $db --quiet --eval "var doc=db.$b.files.findOne({'metadata.pid':'$pid'}, {_id:1});if ( doc ){print(doc._id)}")
        if [ -z "$files_id" ] ; then
            echo "No derivative in level ${b} found."
        else
            echo "Remove derivative ${b}"
            mongo "$db" --quiet --eval "db.$b.files.remove({_id:$files_id})"
            mongo "$db" --quiet --eval "db.$b.chunks.remove({files_id:$files_id})"
            mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'; var del=true;" $(cwp "$scripts/shared/vfs.js")
        fi
    done
fi



# Add to the statistics
add_statistic="$add_statistic"
if [ "$add_statistic" == "yes" ]
then
    mongo $db --quiet --eval "var pid = '$pid';var ns='$bucket';" $scripts/shared/statistics.js
fi

# Add to the vfs
add_vfs="$add_vfs"
if [ "$add_vfs" == "yes" ]
then
    mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'" $(cwp "$scripts/shared/vfs.js")
fi

remove="$remove"
if [ "$remove" == "yes" ]
then
    rm "$l"
    rm "$l.md5"
    exit 0
fi
