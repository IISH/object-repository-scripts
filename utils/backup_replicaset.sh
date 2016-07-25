#!/bin/bash
#
# /shared/backup_replicaset.sh
#
# Backup a replica set by exporting filestreams plus their metadata.
#
# Gridfs stores files in two collections# [bucket].files and [bucket].chunks
# Given a normalized md5 string of 32 characters, then a file and its metadata is exported as:
# /[replica set]/[db]/[first 8 md5 of the file]/[second 8 md5 chars]/[third 8]/[md5].bin
# /[replica set]/[db]/[first 8 md5 of the file]/[second 8 md5 chars]/[third 8]/[md5].json
#
# Usage# backup_replicaset.sh [metadata host] [primary host] [db] [bucket] [target]
# E.g. ./backup_replicaset.sh or_10622 master /some/device/mountpoint


#-----------------------------------------------------------------------------------------------------------------------
# Gather and validate the arguments.
#-----------------------------------------------------------------------------------------------------------------------
bucket_files_host=$1
if [ -z "$bucket_files_host" ]
then
    echo "Must have a host name of the replica set that contains the files collection."
    exit 1
fi

bucket_chunks_host=$2
if [ -z "$bucket_chunks_host" ]
then
    echo "Must have a host name of the replica set that contains the chunks collection."
    exit 1
fi

db=$3
if [ -z "$db" ]
then
    echo "Must have a database name"
    exit 1
fi

bucket=$4
if [ -z "$bucket" ]
then
    echo "Must have a collection name for the metadata and chunks collection"
    exit 1
fi

count_bucket_files=$(mongo "${bucket_files_host}/${db}" --quiet --eval "db.${bucket}.files.count()")
rc=$?
if [[ $rc != 0 ]]
then
    echo "Error trying to count the number of documents."
    exit 1
fi
if [[ $count_bucket_files == 0 ]]
then
    echo "No collection ${bucket}.files found on ${bucket_files_host}/${db}"
    exit 1
else
    echo "Found ${count_bucket_files} metadata documents on ${bucket_files_host}/${db}"
fi

count_bucket_chunks=$(mongo "${bucket_chunks_host}/${db}" --quiet --eval "db.${bucket}.chunks.count()")
rc=$?
if [[ $rc != 0 ]]
then
    echo "Error trying to count the number of documents."
    exit 1
fi
if [[ $count_bucket_chunks == 0 ]]
then
    echo "No collection ${bucket}.chunks found on ${bucket_chunks_host}/${db}"
    exit 1
else
    echo "Found ${count_bucket_chunks} chunk documents on ${bucket_chunks_host}/${db}"
fi

target=$5
if [ -z "$target" ]
then
    echo "Must have a target folder"
    exit 1
fi
if [ ! -d "$target" ]
then
    echo "Directory not found ${target}"
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Get dependencies.
#-----------------------------------------------------------------------------------------------------------------------
ORFILES="/opt/orfiles-1.0.jar"
wget -O "$ORFILES" --no-check-certificate "https://bamboo.socialhistoryservices.org/browse/OR-SERVICENODES/latestSuccessful/artifact/JOB1/orfiles/orfiles-1.0.jar"


#-----------------------------------------------------------------------------------------------------------------------
# Get a list of all identifiers on the replica set.
#-----------------------------------------------------------------------------------------------------------------------
file_with_identifiers="/opt/_id.${db}.${bucket}.txt"
if [ ! "file_with_identifiers" ]
then
    rm "$file_with_identifiers"
fi

# This can take to long:
# mongo "${bucket_chunks_host}/${db}" --quiet --eval "db.${bucket}.chunks.find({files_id:{\$ne:0},n:0},{_id:0, files_id:1}).forEach(function(d){print(d.files_id)})" > "$file_with_identifiers"
maxKey=$(mongo "${bucket_chunks_host}/${db}" --quiet --eval "db.${bucket}.chunks.find({files_id:{\$ne:0},n:0},{_id:0, files_id:1}).limit(1).sort({files_id:-1})[0].files_id")
rc=$?
if [[ $rc == 0 ]]
then
    echo "maxKey: ${maxKey}"
else
    echo "Unable to get the maxKey with identifiers (${rc}): ${file_with_identifiers}"
    exit 1
fi

minKey=$(mongo "${bucket_chunks_host}/${db}" --quiet --eval "db.${bucket}.chunks.find({files_id:{\$ne:0},n:0},{_id:0, files_id:1}).limit(1).sort({files_id:1})[0].files_id")
rc=$?
if [[ $rc == 0 ]]
then
    echo "minKey: ${minKey}"
else
    echo "Unable to get the minKey with identifiers (${rc}): ${file_with_identifiers}"
    exit 1
fi

mongo "${bucket_files_host}/${db}" --quiet --eval "db.${bucket}.files.find({\$and:[{_id:{\$gte:${minKey}}},{_id:{\$lte:${maxKey}}},md5:{\$exists:true}]},{_id:1}).sort({_id:1}).forEach(function(d){print(d._id)})" > "$file_with_identifiers"
rc=$?
if [[ $rc != 0 ]]
then
    echo "Unable to get a file with identifiers: ${file_with_identifiers}"
    exit 1
fi
count=$(cat "$file_with_identifiers" | wc -l)
if [[ $count == 0 ]]
then
    echo "No identifiers found."
    exit 1
fi

if [[ $count_bucket_files != $count ]]
then
    echo "Warning... ${count} documents stored, but ${count_bucket_files} expected."
fi


#-----------------------------------------------------------------------------------------------------------------------
# Extract all files.
#-----------------------------------------------------------------------------------------------------------------------
while read id
do
    echo "Checking out ${id}"
    md5_expected=$(mongo "${bucket_files_host}/${db}" --quiet --eval "var doc=db.${bucket}.files.findOne();assert(doc);assert(doc.md5);print(doc.md5)")
    rc=$?
    if [[ $rc != 0 ]]
    then
        echo "Error ${rc} with ${id}"
        continue
    fi

    md5_expected="00000000000000000000000000000000${md5_expected}"
    md5_expected=${md5_expected:(-32)}
    md5_part1="${md5_expected:0:8}"
    md5_part2="${md5_expected:8:8}"
    md5_part3="${md5_expected:16:8}"
    md5_part4="${md5_expected:24:8}"
    path="${target}/${md5_part1}/${md5_part2}/${md5_part3}/${md5_part4}"
    if [ ! -d "$path" ]
    then
        mkdir -p "$path"
    fi
    file_binary="${path}/${id}.bin"
    if [ -f "$file_binary" ]
    then
        rm "$file_binary"
    fi
    java -jar "$ORFILES" -M Get -l "$file_binary" -h "$bucket_files_host" -d "$db" -b "$bucket" -s "$id" -a "some_pid" -m "some_md5"
    rc=$?
    if [[ $rc != 0 ]]
    then
        echo "Error ${rc} with ${id}"
        continue
    fi

    md5_actual=$(md5sum "$file_binary" | cut -d ' ' -f 1)
    md5_actual="00000000000000000000000000000000${md5_actual}"
    md5_actual=${md5_actual:(-32)}
    if [ "$md5_expected" == "$md5_actual" ]
    then
        echo "md5 checksum ok ${md5_actual}"
    else
        echo "md5 mismatch then comparing the file with a checkout version."
        echo "Expect ${md5_expected} but got ${md5_actual}  ${file_binary}"
    fi

    file_metadata="${path}/${id}.json"
    if [ -f "$file_metadata" ]
    then
        rm "$file_metadata"
    fi
    mongo "${bucket_files_host}/${db}" --quiet --eval "printjson(db.${bucket}.files.findOne());" > "$file_metadata"
    rc=$?
    if [[ $rc != 0 ]]
    then
        echo "Error ${rc} saving ${file_metadata}"
        continue
    fi

done < "$file_with_identifiers"