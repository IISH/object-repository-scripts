#!/bin/bash
#
# /InstructionPackage/startup.sh
#
# Build a rar package and a whole new instruction around it.
#
# We run three commands with options:
#
# Command 1:         create the archive.
# rar a              Add files to archive.
#   -m0              Store files. So no compression.
#   -rr5%            Optionally, redundant information (recovery record) may be added to an archive, incurring a small
#                        penalty in archive size, which will help to recover archived files in the case of a diskette
#                        failure or other data losses.
#   -v107374182400b  100GiB multipart package.
#   -x*.md5          Ignore files with a .md5 postfix.
#   -r               Recurse subdirectories.
#
# Command 2:         Test the archive
# rar t -r '*'
#
# Command 2:         lock the archive.
# rar k              Lock archive. Any command which intend to change the archive will be ignored.

scripts=$scripts
source $scripts/shared/parameters.sh
fileSet=$fileSet
archiveID=$(basename "$fileSet")
workdir="$(dirname "$fileSet")/.work"
archive="${workdir}/${archiveID}.rar"


#-----------------------------------------------------------------------------------------------------------------------
# Remove stale working.
#-----------------------------------------------------------------------------------------------------------------------
if [ -d "$workdir" ]
then
    echo "Found working directory. Deleting: ${workdir}"
    rm -rf "$workdir"
fi


#-----------------------------------------------------------------------------------------------------------------------
# Create the archive.
#-----------------------------------------------------------------------------------------------------------------------
rar a -m0 -r -rr5% -v107374182400b "$archive" "$fileSet"
rc=$?
if [[ $rc != 0 ]] ; then
    echo "rar 'a' command returned an error ${rc}"
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Lock archive.
#-----------------------------------------------------------------------------------------------------------------------
rar r "$archive" "$fileSet"
if [[ $rc != 0 ]] ; then
    echo "rar 'r' command returned an error ${rc}"
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Test archive.
#-----------------------------------------------------------------------------------------------------------------------
rar t -r '*' "$archive" "$fileSet"
rc=$?
if [[ $rc != 0 ]] ; then
    echo "rar 't' command returned an error ${rc}"
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Create the SIP
#-----------------------------------------------------------------------------------------------------------------------



#-----------------------------------------------------------------------------------------------------------------------
# Move the fileSet to the working directory.
#-----------------------------------------------------------------------------------------------------------------------
mv "$fileSet" "$workdir"




exit 0