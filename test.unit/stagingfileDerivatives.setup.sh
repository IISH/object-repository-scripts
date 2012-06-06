#!/bin/bash

# Here we have a simple tiff which we will pull from a reserved area

scripts=$scripts
sa_path=$sa_path
na="12345"
cpuser=testuser
folder=unittest/TIFF
fileName="1_0001.tif"
fileSet=$sa_path/$na/$cpuser/unittest

# Our "master" file is here as it should be in the instruction:
pid="$na/1"
location="/$folder/$fileName"
contentType="image/tiff"
db=or_$na

if [ ! -d $fileSet ]; then
    mkdir -p $fileSet
fi

# We keep the test master and custom derivatives here:
d="$sa_path/$na/.$cpuser/unittest"
if [ ! -d $d ]; then
    echo "Error: cannot find test master directory $d"
    exit 0
fi
echo "Using test directory $d"

# copy the test file to the ftp directory. We dare a rm -r here, because we know fileSet is not empty and the command
# has a /TIFF attached to it.
rm -r /mnt/sa/12345/testuser/unittest
cp -r -v $d $fileSet
testfile=$fileSet/TIFF/1_0001.tif
if [ ! -f $testfile ]; then
    echo "No testfile found: $testfile"
fi

md5=$(md5sum $testfile | cut -d ' ' -f 1)

