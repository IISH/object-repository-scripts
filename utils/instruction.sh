#!/bin/bash

access="closed"
deleteCompletedInstruction="false"
notificationEMail="lwo@iisg.nl"
na="20.500.12012"


function stagingfile {

    archiveID="$1"
    file="$2"

    filename=$(basename "$file")
    if [[ "$filename" =~ ^.*_([0-9]+)\.jpg$ ]]
    then
        seq="${BASH_REMATCH[1]}"
    else
        echo "Could not extract the sequence number from the file part: ${filename}"
        exit 1
    fi

    location="/${archiveID}/${filename}"
    md5=$(cat "${file}.md5" | cut -d ' ' -f 1)
    id=$(cat /proc/sys/kernel/random/uuid)
    pid="${na}/${id^^}"

    echo "
    <stagingfile>
      <location>${location}</location>
      <md5>${md5}</md5>
      <pid>${pid}</pid>
      <seq>${seq}</seq>
    </stagingfile>
    "
}


function instruction {

    folder="$1"
    id=${folder:9:3}
    label="$folder"
    objid="${na}/${id}"

    #-------------------------------------------------------------------------------------------------------------------
    # We have a valid archive. Create the SIP.
    #-------------------------------------------------------------------------------------------------------------------
    file_instruction="${folder}/instruction.xml_"
    echo "<instruction
        xmlns='http://objectrepository.org/instruction/1.0/'
        access='$access'
        autoIngestValidInstruction='false'
        deleteCompletedInstruction='$deleteCompletedInstruction'
        label='$label'
        action='add'
        contentType='image/jpeg'
        notificationEMail='$notificationEMail'
        plan='StagingfileIngestMaster,StagingfileBindObjId,StagingfileBindPIDs'
        objid='$objid'
        >" > "$file_instruction"

    for file in "$folder/"*.jpg
    do
        stagingfile "$folder" "$file" >> "$file_instruction"
    done

    echo "</instruction>" >> "$file_instruction"
}


function main {
    for folder in VGH-250G-*
    do
        echo "$folder"
        instruction "$folder"
    done
}


main


exit 0