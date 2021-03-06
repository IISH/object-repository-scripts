#!/bin/bash
#
# StagingFileIngestMaster/startup.sh
#
# Insert a Master file into the database

scripts=$scripts
fileSet=$fileSet
bucket="master"
source $scripts/shared/parameters.sh
derivative=$derivative
db=$db
length=$length
md5=$md5
pid=$pid
access=$access
contentType=$contentType
label="$label"
l="$l"
action=$action

source $scripts/shared/delete.sh


add_backup="yes"
add_vfs="yes"
remove="yes"
remove_derivatives="yes"
validate_file="yes"

# If we find a file we upload it
mongo $db --quiet --eval "db.label.update( {'_id' : '$label'}, {\$inc:{size:1}}, true, false)"
if [ -f "$l" ] ; then
    source $scripts/shared/put.sh
else
    echo "No location '$l' found... updating metadata for the $db.$bucket collection"
    query="{'metadata.pid':'$pid'}"
    update=""
    for key in access embargo embargoAccess contentType label objid seq
    do
        value=$(eval "echo \$${key}")
        if [ -z "$value" ] ; then
            echo "$key not set... it will not be updated."
        else
            if [[ "$value" == "null" ]] || [[ "$value" == "NULL" ]] || [[ "$value" == 0 ]] ; then
                # This element should not be set but kept.
                echo "Not setting element ${key}"
            else
                if [ "$value" -eq "$value" ] 2>/dev/null; then
                    # This is an integer
                    update="${update}'metadata.${key}':${value},"
                else
                    update="${update}'metadata.${key}':'${value}',"
                fi
            fi
        fi
    done

    if [ -z "$update" ] ; then
        echo "Nothing to update."
        exit 245
    fi

    # remove the last comma and enclose with {}
    update="{${update%?}}"
    mongo $db --quiet --eval "db.getCollection('$bucket.files').update($query,{\$set:$update}, false, false);''"
    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    # Verify
    query="{\$and:[$query,$update]}"
    countOne=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
    if [ $countOne == 1 ] ; then
	    echo "File metadata updated."
	    # Update the other buckets.
        for c in level3.files level2.files level1.files
        do
            mongo $db --quiet --eval "db.$c.update({'metadata.pid':'$pid'}, {\$set:$update}, false, false)"
        done
	    exit 0
    fi
    echo "The expected updated elements cannot be found with the query $query"
    exit 245

    # Add to the vfs
    if [ "$add_vfs" == "yes" ]
    then
        mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'" $(cwp "$scripts/shared/vfs.js")
    fi
fi

exit $?
