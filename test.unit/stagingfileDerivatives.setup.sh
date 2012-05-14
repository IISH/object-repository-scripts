#!/bin/bash

scripts=$scripts
na="12345"
sa_path=$sa_path
cpuser=testuser
folder=unittest/TIFF
fileName="1_0001.tif"
fileSet=$sa_path/$na/$cpuser/unittest
testfile=$fileSet/TIFF/$fileName
pid="$na/1"
location="/$folder/$fileName"
contentType="image/tiff"
db=or_$na

testTotal=4
testCounter=0

mkdir -p $fileSet
rm $fileSet/*
f="$sa_path/$na/.$cpuser/$folder/$fileName"
mkdir -p $fileSet/TIFF/
cp $f $testfile
md5=$(md5sum $testfile | cut -d ' ' -f 1)


# For the derivatives we use a text/plain
folder1="$fileSet/.level1/"
folder2="$sa_path/$na/$cpuser/unittest/.level2/"
folder2="$sa_path/$na/$cpuser/unittest/.level3/"
mkdir -p $folder1
mkdir -p $folder2
mkdir -p $folder3
rm $folder1/*
rm $folder2/*
rm $folder3/*


