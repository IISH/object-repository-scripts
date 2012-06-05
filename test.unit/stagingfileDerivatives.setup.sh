#!/bin/bash

scripts=$scripts
sa_path=$sa_path
na="12345"
cpuser=testuser
folder=unittest/TIFF
fileName="1_0001.tif"
fileSet=$sa_path/$na/$cpuser/unittest

# Our "master" file is here
testfile=$fileSet/TIFF/$fileName
pid="$na/1"
location="/$folder/$fileName"
contentType="image/tiff"
db=or_$na

mkdir -p $fileSet
rm $fileSet/*

# We keep the test master here in $f
f="$sa_path/$na/.$cpuser/$folder/$fileName"
if [ ! -f $f ]; then
    echo "Error: cannot find test master file $f"
    exit 0
fi

mkdir -p $fileSet/TIFF/
cp $f $testfile
md5=$(md5sum $testfile | cut -d ' ' -f 1)


# Clear earlier test derivative material
folder1="$fileSet/.level1/"
folder2="$sa_path/$na/$cpuser/unittest/.level2/"
folder3="$sa_path/$na/$cpuser/unittest/.level3/"
mkdir -p $folder1
mkdir -p $folder2
mkdir -p $folder3
rm $folder1/*
rm $folder2/*
rm $folder3/*


