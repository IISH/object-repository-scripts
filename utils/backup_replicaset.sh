#!/bin/bash
#
# /shared/backup_replicaset.sh
#
# Backup a replica set by exporting filestreams plus their metadata.
#
# Gridfs stores files in two collections# [BUCKET].files and [BUCKET].chunks
# A file and its metadata is exported as:
# /[TARGET FOLDER]/[ID PARTS]/[ID].bin
# /[TARGET FOLDER]/[ID PARTS]/[ID].json
#
# Usage
# backup_replicaset.sh [metadata host] [primary host] [DB] [BUCKET] [TARGET] [optional KEEP_PREVIOUS_FILES=yes|no]
# E.g. ./backup_replicaset.sh or_10622 master /some/device/mountpoint
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

count_bucket_files=$(mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval "DB.${BUCKET}.files.count()")
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Error trying to count the number of documents."
    exit 1
fi
if [[ ${count_bucket_files} == 0 ]]
then
    echo "No collection ${BUCKET}.files found on ${BUCKET_FILES_HOST}/${DB}"
    exit 1
else
    echo "Found ${count_bucket_files} metadata documents on ${BUCKET_FILES_HOST}/${DB}"
fi

count_bucket_chunks=$(mongo "${BUCKET_CHUNKS_HOST}/${DB}" --quiet --eval "DB.${BUCKET}.chunks.count()")
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Error trying to count the number of documents."
    exit 1
fi
if [[ ${count_bucket_chunks} == 0 ]]
then
    echo "No collection ${BUCKET}.chunks found on ${BUCKET_CHUNKS_HOST}/${DB}"
    exit 1
else
    echo "Found ${count_bucket_chunks} chunk documents on ${BUCKET_CHUNKS_HOST}/${DB}"
fi

TARGET=$5
if [ -z "$TARGET" ]
then
    echo "Must have a TARGET folder"
    exit 1
fi
if [ ! -d "$TARGET" ]
then
    echo "Directory not found ${TARGET}"
    exit 1
fi


KEEP_PREVIOUS_FILES="6"
if [ -z "$KEEP_PREVIOUS_FILES" ]
then
    KEEP_PREVIOUS_FILES="yes"
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
if [ ! "file_with_identifiers" ]
then
    rm "$file_with_identifiers"
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

mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval \
    "db.${BUCKET}.files.find({\$and:[{_id:{\$gte:${minKey}}},{_id:{\$lte:${maxKey}}},md5:{\$exists:true}]},{_id:1}).sort({_id:1}).forEach(function(d){print(d._id)})" > "$file_with_identifiers"
rc=$?
if [[ ${rc} != 0 ]]
then
    echo "Unable to get a file with identifiers: ${file_with_identifiers}"
    exit 1
fi
count=$(cat "$file_with_identifiers" | wc -l)
if [[ ${count} == 0 ]]
then
    echo "No identifiers found."
    exit 1
fi

if [[ ${count_bucket_files} != ${count} ]]
then
    echo "Warning... ${count} documents stored, but ${count_bucket_files} expected."
fi


#-----------------------------------------------------------------------------------------------------------------------
# Extract all files.
#-----------------------------------------------------------------------------------------------------------------------
while read id
do
    echo -n "Checking out ${id}... "
    md5_expected=$(mongo "${BUCKET_FILES_HOST}/${DB}" --quiet --eval "var doc=db.${BUCKET}.files.findOne({_id:${id});assert(doc);assert(doc.md5);print(doc.md5)")
    rc=$?
    if [[ ${rc} == 0 ]]
    then
        md5_expected=$(normalize_md5_hash "$md5_expected")
    else
        echo "ERROR ${rc} with ${id} when retrieving the expected md5 from the files collection ${BUCKET_FILES_HOST}."
        continue
    fi

    path=$(build_path "$id")
    if [ ! -d "$path" ]
    then
        mkdir -p "$path"
    fi

    file_metadata="${path}/${id}.json"
    file_binary="${path}/${id}.bin"

    # if the file already exist, we check if the md5 still holds true. Otherwise we remove it.
    # There is a risk here... what is the file was corrupted in the database after it was downloaded?
    # Hence the flag: ignore_previous_files
    if [ -f "$file_binary" ]
    then
        if [ "$KEEP_PREVIOUS_FILES" == "yes" ]
        then
            md5_actual=$(md5_from_file "$file_binary")
            if [ "$md5_expected" != "$md5_actual" ]
            then
                rm "${file_binary}"
            fi
        else
            rm "${file_binary}"
        fi
    fi


    # Download the file.
    if [ ! -f "$file_binary" ]
    then
        java -jar "$ORFILES" -M Get -l "$file_binary" -h "$BUCKET_FILES_HOST" -d "$DB" -b "$BUCKET" -s "$id" -a "some_pid" -m "some_md5"
        rc=$?
        if [[ ${rc} != 0 ]]
        then
            echo "ERROR ${rc} when downloading file with ${id}"
            continue
        fi
        md5_actual=$(md5_from_file "$file_binary")
        if [ "$md5_expected" != "$md5_actual" ]
        then
            echo "ERROR: md5 mismatch then comparing the file with a checkout version. \
                Expect ${md5_expected} but got ${md5_actual}  ${file_binary}"
            continue
        fi
    fi


    save_metadata "$id" "$file_metadata"
    rc=$?
    if [[ ${rc} != 0 ]]
    then
        echo "ERROR ${rc} saving the file's ${file_metadata}"
        continue
    fi

    # If we got here then the binary and it's metadata is saved to disk.
    echo "OK"

done < "$file_with_identifiers"