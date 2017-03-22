#!/bin/bash

token="9863fad7-6529-4023-b82c-b4ed272e4c5c"
base_url="https://admin.objectrepository.org/file/master"
na="10622"
bulk="$1"
n="$2"

folder=".tmp"
mkdir "$folder"


for i in $(seq 1 ${n})
do
    url="${base_url}/${na}/${bulk}.${i}"
    echo "$url"
    wget --no-check-certificate --header="Authorization: bearer ${token}" -S ${url} -O "${folder}/${bulk}.part${i}.rar"
done

echo "unrar..."
unrar e "${folder}/${bulk}.part1.rar"
rc=$?
if [[ ${rc} == 0 ]]
then
    fileSet=$(pwd)
    echo "Remove: ${fileSet}"
    mongo sa --quiet --eval "db.getCollection('stagingfile').remove({fileSet:'$fileSet'})"
    mongo sa --quiet --eval "db.getCollection('instruction').remove({fileSet:'$fileSet'})"
fi

rm -rf "$folder"