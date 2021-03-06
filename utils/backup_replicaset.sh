#!/bin/bash
#
# /shared/backup_replicaset.sh
#
# Backup a replica set by exporting filestreams: binary plus metadata.
#
# Gridfs stores files in two collections# [BUCKET].files and [BUCKET].chunks
# A file and its metadata is exported as:
# /[TARGET FOLDER]/[ID PARTS]/[ID].bin
# /[TARGET FOLDER]/[ID PARTS]/[ID].json
#
# Usage
# backup_replicaset.sh "metadata host" "primary host" "DB" "BUCKET" "TARGET" "[user]@[HOST]:[folder]"
# E.g. ./backup_replicaset.sh or_10622 master /some/device/mountpoint
#
# WARNING: the target parameter is a folder that will be removed. Do not point it to persistent storage folders.
#
# The procedure will log the ID of the file and success or reason of failure.


#-----------------------------------------------------------------------------------------------------------------------
# Gather and validate the arguments.
#-----------------------------------------------------------------------------------------------------------------------
BUCKET_FILES_HOST=$1
if [ -z "$BUCKET_FILES_HOST" ]
then
    echo "Must have a host name of the replica set that contains the files collection."
    exit 1
fi

BUCKET_CHUNKS_HOST=$2
if [ -z "$BUCKET_CHUNKS_HOST" ]
then
    echo "Must have a host name of the replica set that contains the chunks collection."
    exit 1
fi

DB=$3
if [ -z "$DB" ]
then
    echo "Must have a database name"
    exit 1
fi

BUCKET=$4
if [ -z "$BUCKET" ]
then
    echo "Must have a collection name for the metadata and chunks collection"
    exit 1
fi

TARGET=$5
if [ -z "$TARGET" ]
then
    echo "Must have a TARGET folder"
    exit 1
fi
if [ -d "$TARGET" ]
then
    rm -rf "$TARGET"
fi
mkdir -p "$TARGET"

REMOTE_HOST=$6
if [ -z "$REMOTE_HOST" ]
then
    echo "Must have a REMOTE_HOST, e.g. [user]@[ip]:[folder]"
    exit 1
fi

count_bucket_files=$(mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval "db.${BUCKET}.files.count()")
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Error trying to count the number of documents from ${count_bucket_files}."
    exit 1
fi
if [[ ${count_bucket_files} == 0 ]]
then
    echo "No collection ${BUCKET}.files found on ${BUCKET_FILES_HOST}/${DB}"
    exit 1
else
    echo "Found ${count_bucket_files} metadata documents on ${BUCKET_FILES_HOST}/${DB}"
fi

count_bucket_chunks=$(mongo "${BUCKET_CHUNKS_HOST}/${DB}" --quiet --eval "db.${BUCKET}.chunks.count()")
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Error trying to count the number of documents from ${count_bucket_chunks}."
    exit 1
fi
if [[ ${count_bucket_chunks} == 0 ]]
then
    echo "No collection ${BUCKET}.chunks found on ${BUCKET_CHUNKS_HOST}/${DB}"
    exit 1
else
    echo "Found ${count_bucket_chunks} chunk documents on ${BUCKET_CHUNKS_HOST}/${DB}"
fi




#-----------------------------------------------------------------------------------------------------------------------
# Calculate the md5 from a file.
#-----------------------------------------------------------------------------------------------------------------------
function md5_from_file {
    file="$1"
    md5=$(md5sum "$file" | cut -d ' ' -f 1)
    echo -n $(normalize_md5_hash ${md5})
}

#-----------------------------------------------------------------------------------------------------------------------
# Normalize an md5 hash into 32 characters by filling up the left side with trailing zeros.
#-----------------------------------------------------------------------------------------------------------------------
function normalize_md5_hash {
    md5="00000000000000000000000000000000${1}"
    md5=${md5:(-32)}
    echo -n "$md5"
}


#-----------------------------------------------------------------------------------------------------------------------
# Normalize an md5 hash into 32 characters by filling up the left side with trailing zeros.
#-----------------------------------------------------------------------------------------------------------------------
function save_metadata {

    id="$1"
    file_metadata="$2"
    if [ -f "$file_metadata" ]
    then
        rm "$file_metadata"
    fi
    mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval "printjson(db.${BUCKET}.files.findOne({_id:${id}}));" > "$file_metadata"
}


#-----------------------------------------------------------------------------------------------------------------------
# Create a path based on a 12 zero leader divided into three parts.
#-----------------------------------------------------------------------------------------------------------------------
function build_path {

    id="$1"

    case "${id:0:1}" in
        "-")
            alias_id="${id:1}"
            file_part_0="-"
        ;;
        *)
            alias_id="$id"
            file_part_0=""
        ;;
    esac
    file_fill="000000000000${alias_id}"
    file_part_1="${file_fill:(-12):4}"
    file_part_2="${file_fill:(-8):4}"
    file_part_3="${file_fill:(-4):4}"
    path="${TARGET}/${file_part_0}${file_part_1}/${file_part_2}/${file_part_3}"
    echo -n "$path"
}



#-----------------------------------------------------------------------------------------------------------------------
# Get dependencies.
#-----------------------------------------------------------------------------------------------------------------------
ORFILES="/opt/orfiles-1.0.jar"
wget -O "$ORFILES" --no-check-certificate "https://bamboo.socialhistoryservices.org/browse/OR-SERVICENODES/latestSuccessful/artifact/JOB1/orfiles/orfiles-1.0.jar"


#-----------------------------------------------------------------------------------------------------------------------
# Get a list of all identifiers on the replica set.
#-----------------------------------------------------------------------------------------------------------------------
file_with_identifiers="/opt/_id.${DB}.${BUCKET}.txt"
if [ -f "file_with_identifiers" ]
then
    rm "$file_with_identifiers"
fi


minKey=$(mongo "${BUCKET_CHUNKS_HOST}/${DB}" --quiet --eval \
    "db.${BUCKET}.chunks.find({files_id:{\$ne:0},n:0},{_id:0, files_id:1}).limit(1).sort({files_id:1})[0].files_id")
rc=$?
if [[ ${rc} == 0 ]]
then
    echo "minKey: ${minKey}"
else
    echo "Unable to get the minKey with identifiers (${rc}): ${file_with_identifiers}"
    exit 1
fi


maxKey=$(mongo "${BUCKET_CHUNKS_HOST}/${DB}" --quiet --eval \
    "db.${BUCKET}.chunks.find({files_id:{\$ne:0},n:0},{_id:0, files_id:1}).limit(1).sort({files_id:-1})[0].files_id")
rc=$?
if [[ ${rc} == 0 ]]
then
    echo "maxKey: ${maxKey}"
else
    echo "Unable to get the maxKey with identifiers (${rc}): ${file_with_identifiers}"
    exit 1
fi


mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval \
    "db.${BUCKET}.files.find({\$and:[{_id:{\$gte:${minKey}}},{_id:{\$lte:${maxKey}}},{md5:{\$exists:true}}]},{_id:1}).sort({_id:1}).forEach(function(d){print(d._id)})" > "$file_with_identifiers"
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Error ${rc}. Unable to get a file with identifiers: ${file_with_identifiers}"
    exit 1
fi
count=$(cat "$file_with_identifiers" | wc -l)
if [[ ${count} == 0 ]]
then
    echo "No identifiers found."
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Extract all files.
#-----------------------------------------------------------------------------------------------------------------------
echo "Begin"
while read id
do
    ok=1
    while [[ ${ok} != 0 ]]
    do
        echo -n "Checking out ${id}... "
        md5_expected=$(mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval "var doc=db.${BUCKET}.files.findOne({_id:${id}});assert(doc);assert(doc.md5);print(doc.md5)")
        ok=$?
        if [[ ${ok} == 0 ]]
        then
            md5_expected=$(normalize_md5_hash "$md5_expected")
        else
            echo "WARNING ${ok} with ${id} when retrieving the expected md5 from the files collection ${BUCKET_FILES_HOST}. Pausing for 300 seconds."
            sleep 300
        fi
    done

    path=$(build_path "$id")
    if [ ! -d "$path" ]
    then
        mkdir -p "$path"
    fi

    file_metadata="${path}/${id}.json"
    file_binary="${path}/${id}.bin"


    # Download the file.
    java -Xmx1024M -jar "$ORFILES" -M Replica -l "$file_binary" -h "$BUCKET_FILES_HOST" -r "$BUCKET_CHUNKS_HOST" -d "$DB" -b "$BUCKET" -s "$id" -a "some_pid" -m "some_md5"
    ok=$?
    if [[ ${ok} == 0 ]]
    then
        md5_actual=$(md5_from_file "$file_binary")
        if [ "$md5_expected" != "$md5_actual" ]
        then
            ok=1
            echo "md5 mismatch then comparing file ${id}. Expect ${md5_expected} but got ${md5_actual}  ${file_binary}"
        fi
    else
        echo "${ok} when downloading file with ${id}"
    fi


    save_metadata "$id" "$file_metadata"
    ok=$?
    if [[ ${ok} != 0 ]]
    then
        echo "${ok} saving the file's ${file_metadata}"
    fi

    # If we got here with an ok=0 then the binary and it's metadata is saved to disk.
    if [[ ${ok} == 0 ]]
    then
        rsync -av --size-only "${TARGET}/" "$REMOTE_HOST"
        ok=$?
        if [[ ${ok} == 0 ]]
        then
            echo "OK"
        else
            echo "${ok} when performing rsync ${TARGET}/ ${REMOTE_HOST}"
            echo "ERROR"
        fi
    fi

    rm -rf "$TARGET"
    mkdir -p "$TARGET"

done < "$file_with_identifiers"
echo "End"