#!/bin/bash
#
# Reading and setting parameters
#

# Instantiate all command line parameters into key-value pairs
# We trust the agent gave us a key-value pair list, where the key always begins with a hyphen and has a value:
# -[keyname] [value]
# We set IFS to NULL to avoid splitting the value

IFS=
while [ "${1+isset}" ]; do
 k=${1:1}
    shift
 v=$1
    shift
    eval ${k}=$(echo \""${v}"\")
    echo "$k=$v"
        if [[ ${v:0:1} == "-" ]]; then
            echo "Value cannot start with a hyphen."
            exit -1
        fi
done
unset IFS

sa_path=$sa_path
content=$content
contentType=$contentType
database=$database
na=$na
db="$database"_"$na"
endpoint=$endpoint
fileSet=$fileSet
key=$key
l=$l
location=$location
pidwebserviceEndpoint=$pidwebserviceEndpoint
pidwebserviceKey=$pidwebserviceKey

if [ -z "$sa_path" ] ; then
    echo "Path sa_path not set as environment variable."
    exit -1
fi

if [ ! -d "$sa_path" ] ; then
    echo "Path sa_path '$sa_path' not found."
    exit -1
fi

# Some normalizations
# As the location in the supplied stagingfile is not absolute, but taken from the point of view of a ftp
# home directory, we need to make it absolute.
# We keep the original instruction/stagingfile/location element as instruction_location to add to the metadata
#
# Example:      FileSet =       /a/b/c/d
#               location =      /d/e/f
# must be       location =      /a/b/c/d/e/f
if [ ! -z "$location" ]; then

    if [ -z "$instruction_location" ]; then
        instruction_location=$(dirname "$location")
    fi

	location=$(dirname "$fileSet")$location
	if [ -z "$l" ]; then
        	l=$location
	fi
	if [ -f "$l" ] ; then
		length=$(stat -c%s "$l")
	else
		length=0
	fi
fi
echo "length=$length"
echo "location=$location"

# Split the contentType [family/type] into two separate variables. Example:
# contentType = image/jpeg => derivative:image,sourceFileExtension=jpeg
sentence=${contentType//\//$' '}  # change the / to the separator white space
i=0;
for word in $sentence
    do
            a[$i]=$word;
            let i++;
    done
derivative=${a[0]}
sourceFileExtension=${a[1]}

# Should the content NOT be a json string, we nullify it
if [[ ${content:0:1} == "{" ]]; then
	echo "Content: $content"
else
	content=null
fi

# If no webservice endpoint or key was given, we supply a custom value
if [ -z "$pidwebserviceEndpoint" ]; then
    pidwebserviceEndpoint=$endpoint
fi


if [ -z "$pidwebserviceKey" ]; then
    pidwebserviceKey=$key
fi


if [ -z "$autoIngestValidInstruction" ]
then
    autoIngestValidInstruction="false"
fi


if [ -z "$deleteCompletedInstruction" ]
then
    deleteCompletedInstruction="false"
fi

# Normalize the md5 to ensure it is 32 characters in length.
md5="00000000000000000000000000000000${md5}"
md5=${md5:(-32)}


db="$database"_"$na"

statusCode=$statusCode
autoGeneratePIDs=$autoGeneratePIDs
name=$name
access=$access
action=$action
id=$id
resolverBaseUrl=$resolverBaseUrl
identifier=$identifier
plan=$plan
instruction="{instruction:{workflow:{workflow:{name:'$name',statusCode:$statusCode, identifier:'$identifier'}}, \
    fileSet:'$fileSet', autoGeneratePIDs:'$autoGeneratePIDs', resolverBaseUrl:'$resolverBaseUrl', na:'$na', \
    contentType:'$contentType', access:'$access', action:'$action', id:'$id', plan:'$plan'}}"


# As we may be running in cygwin, we add a special function here so scripts can run the cygpath utility.
function cwp {
IFS=
    file="$1"
    if [ -z "$CYGWIN_HOME" ] ; then
        echo "$file"
    else
        echo $(cygpath --windows "$file")
    fi
unset IFS
}

