#!/bin/bash
#
# /InstructionPackage/startup.sh
#
# Build a rar package and a whole new instruction around it.
#
# We run the rar command with these options:
# $ rar a                  Create and add files to archive.
#       -ep1               Exclude base directory from names.
#       -k                 Lock the archive.
#       -m0                Store files. So no compression.
#       -r                 Recurse
#       -rr5%              Optionally, redundant information (recovery record) may be added to an archive, incurring a small
#                                penalty in archive size, which will help to recover archived files in the case of a diskette
#                               failure or other data losses.
#       -t                 Test the archive
#       -v107374182400b    100GiB multipart package.
#       -x*.md5            Ignore files with a .md5 postfix.


scripts=$scripts
source $scripts/shared/parameters.sh
access=$access
fileSet=$fileSet
archiveID=$(basename "$fileSet")
workdir="$(dirname "$fileSet")/.work"
archive="${workdir}/${archiveID}.rar"
expected_archive="${fileSet}/${archiveID}.rar"
expected_archive_part="${fileSet}/${archiveID}.part01.rar"


#-----------------------------------------------------------------------------------------------------------------------
# Check if previous backups of the fileset are there.
#-----------------------------------------------------------------------------------------------------------------------
rc=0
for test_archive in "$expected_archive" "$expected_archive_part"
do
    rar t -r "$test_archive"
    rc=$?
    if [[ $rc == 0 ]] ; then
        echo "Found a valid archive: ${test_archive}"
        break
    fi
done

if [[ $rc != 0 ]] ; then

    #-----------------------------------------------------------------------------------------------------------------------
    # Remove stale working directory.
    #-----------------------------------------------------------------------------------------------------------------------
    if [ -d "$workdir" ]
    then
        echo "Found working directory. Deleting: ${workdir}"
        rm -rf "$workdir"
    fi
    mkdir -p "$workdir"


    #-----------------------------------------------------------------------------------------------------------------------
    # Create a multipart archive of 100GiB.
    #-----------------------------------------------------------------------------------------------------------------------
    rar a -ep1 -k -m0 -r -rr5% -t -v107374182400b -x*.md5 "$archive" "$fileSet"
    rc=$?
    if [[ $rc == 0 ]] ; then
        echo "As we made a rar archive and validated it, we now remove the original SIP."
        perl -e "use File::Path;\$count=rmtree('/tmp/a');print('Removed ' . \$count);"
    else
        echo "rar 'a' command returned an error ${rc}"
        rm "$archive"
        exit 1
    fi
fi


#-----------------------------------------------------------------------------------------------------------------------
# We have a valid archive. Create the SIP
#-----------------------------------------------------------------------------------------------------------------------
instruction="$fileSet/instruction.xml"
echo "<instruction>" >> "$instruction"

for rar_part in "$workdir"
do
    l="${rar_part}.md5"
    md5sum "$rar_part" > "$l"
    md5=$(cat "$l" | cut -d ' ' -f 1)
    location="${fileset}$(basename "$rar_part")"
    echo "<stagingfile>" >> "$instruction"
    echo "</stagingfile>" >> "$instruction"
done
echo "</instruction>" >> "$instruction"






exit 0