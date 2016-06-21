#!/bin/bash
#
# /InstructionPackage/startup.sh
#
# Build a rar package and a whole new instruction around it.
# If the root has a manifest.xml then this is also offered as a master.
#
# RAR from http://rarsoft.com/download.htm
# Linux 64 latest stable, version 5.
#
# We run the rar command with these options:
# $ rar a              Create and add files to archive.
#   -ep1               Exclude base directory from names.
#   -k                 Lock the archive.
#   -m0                Store files. So no compression.
#   -ola               Store symbolic links absolute path.
#   -r                 Recurse
#   -rr5%              Optionally, redundant information (recovery record) may be added to an archive, incurring a
#                        small penalty in archive size, which will help to recover archived files in the case of a
#                        diskette failure or other data losses.
#   -t                 Test the archive
#   -v2147483647b      2 GiB multipart package.
#   -w<path>           Assign work directory
#   -x*.md5            Ignore files with a .md5 postfix.


scripts=$scripts
source $scripts/shared/parameters.sh
access=$access
fileSet=$fileSet
archiveID=$(basename "$fileSet")
workdir_rar="$(dirname "$fileSet")/.work/${archiveID}/.rar"
workdir="$(dirname "$fileSet")/.work/${archiveID}"
archive="${workdir}/${archiveID}.rar"
expected_archive=$(ls -t "${workdir}/$archiveID".part*.rar | tail -n 1)
na=$na
label=$label
notificationEMail=$notificationEMail
objid=$objid


if [ -z "$na" ]
then
    echo "NA not set."
    exit 1
fi

if [ -z "$fileSet" ]
then
    echo "Need a fileSet: ${fileSet}"
    exit 1
fi

if [ -d "$fileSet" ]
then
    echo "Will build a rar package"
else
    if [ ! -d "$workdir" ]
    then
        echo "No fileSet found: ${fileSet}, so expecting a existing working directory ${workdir} but it is not there."
        exit 1
    fi
fi


if [ -z "$objid" ]
then
    objid="${na}/${archiveID}"
fi


#-----------------------------------------------------------------------------------------------------------------------
# We have a valid archive. SHOULD we find a manifest.xml file here, then we will declare it as a master.
#-----------------------------------------------------------------------------------------------------------------------
function manifest {

    file="$1"
    if [ ! -f "$file" ]
    then
        echo "${file} not found."
        exit 1
    fi

    location="/${archiveID}/manifest.xml"
    l="${file}.md5"
    md5sum "$file" > "$l"
    md5=$(cat "$l" | cut -d ' ' -f 1)
    pid="${objid}"

    echo "
    <stagingfile>
        <location>${location}</location>
        <md5>${md5}</md5>
        <pid>${pid}</pid>
        <seq>0</seq>
        <contentType>text/xml</contentType>
    </stagingfile>
    "
}


function stagingfile {

    file="$1"

    filename=$(basename "$file")
    if [[ "$filename" =~ ^.*\.part([0-9]+)\.rar$ ]]
    then
        seq="${BASH_REMATCH[1]}"
    else
        echo "Could not extract the sequence number from the file part: ${filename}"
        exit 1
    fi

    location="/${archiveID}/${filename}"
    l="${file}.md5"
    md5sum "$file" > "$l"
    md5=$(cat "$l" | cut -d ' ' -f 1)
    pid="${objid}.${seq}"

    echo "
    <stagingfile>
      <location>${location}</location>
      <md5>${md5}</md5>
      <pid>${pid}</pid>
      <seq>${seq}</seq>
      <contentType>application/x-rar-compressed</contentType>
    </stagingfile>
    "
}


function instruction {
    #-------------------------------------------------------------------------------------------------------------------
    # We have a valid archive. Create the SIP.
    #-------------------------------------------------------------------------------------------------------------------
    file_instruction="${workdir}/instruction.xml"
    echo "<instruction
        xmlns='http://objectrepository.org/instruction/1.0/'
        access='$access'
        autoIngestValidInstruction='true'
        deleteCompletedInstruction='true'
        label='$label'
        action='add'
        notificationEMail='$notificationEMail'
        plan='StagingfileIngestMaster,StagingfileBindPIDs'
        objid='$objid'
        >" > $file_instruction

    for file in "$workdir/"*.rar
    do
        stagingfile "$file" >> "$file_instruction"
    done

    manifest="${fileSet}/manifest.xml"
    if [ -f "$manifest" ]
    then
        target="${workdir}/manifest.xml"
        cp "${manifest}" "$target"
        manifest "$manifest" >> "$file_instruction"
    fi

    echo "</instruction>" >> "$file_instruction"
}


function package {
    #-------------------------------------------------------------------------------------------------------------------
    # Check if previous backups of the fileset are there.
    #-------------------------------------------------------------------------------------------------------------------
    echo "Check if previous backups of the fileset are there: ${expected_archive}"
    echo "This check may fail."
    rar t "$expected_archive"
    rc=$?
    if [[ $rc == 0 ]] ; then
        echo "Found a valid archive: ${expected_archive}"
    else
        echo "No valid archive found. This is not an error, just a warning."
        #---------------------------------------------------------------------------------------------------------------
        # Remove stale working directory.
        #---------------------------------------------------------------------------------------------------------------
        if [ -d "$workdir" ]
        then
            echo "Found working directory. Deleting: ${workdir}"
            rm -rf "$workdir"
        fi
        mkdir -p "$workdir"


        #---------------------------------------------------------------------------------------------------------------
        # Create a multipart archive. Exclude the .md5 files placed there by the system.
        #---------------------------------------------------------------------------------------------------------------
        mkdir "$workdir_rar"
        rar a -ep1 -k -m0 -ola -r -rr5% -t -v2147483647b -w"$workdir_rar" -x*.md5 "$archive" "$fileSet"
        rc=$?
        rm -rf "$workdir_rar"
        if [[ $rc != 0 ]] ; then
            echo "rar 'a' command on ${archive} ${fileSet} returned an error ${rc}"
            rm -rf "$workdir"
            exit $rc
        fi

        #---------------------------------------------------------------------------------------------------------------
        # If we only have one part, Then rename the file accordingly. This way we always have a sequence number.
        #---------------------------------------------------------------------------------------------------------------
        if [ -f "$archive" ]
        then
            expected_archive="$archive.part01.rar"
            echo "Moving ${archive} to ${expected_archive}"
            mv "$archive" "$expected_archive"
        fi
    fi
}


#-----------------------------------------------------------------------------------------------------------------------
# Here we have our package and can move the working directory to the fileSet.
#-----------------------------------------------------------------------------------------------------------------------
function move_dir {

    if [ -d "$workdir" ]
    then
        if [ -d "$fileSet" ]
        then
            echo "Removing fileSet: ${fileSet}"
            rm -rf "$fileSet"
        fi
        echo "Move working directory ${workdir} to fileSet ${fileSet}"
        mv "$workdir" "$fileSet"
    else
        echo "Expected a working directory ${workdir} to replace the fileSet ${fileSet}, but it is not there."
        exit 1
    fi

}


function main {
    package
    instruction
    move_dir
}


main "$@"


exit 0