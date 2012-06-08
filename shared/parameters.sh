#!/bin/bash
#
# Reading and setting parameters
#

# Instantiate all command line parameters into key-value pairs
# We trust the agent gave us a key-value pair list, where the key always begins with a hyphen and has a value:
# -[keyname] [value]
#
while [ "${1+isset}" ]; do
 k=${1:1}
    shift
 v=$1
    shift
  eval ${k}=$(echo -ne \""${v}"\")
    echo "$k=$v"
	if [ ${v:0:1} == "-" ]; then
	    echo "Value cannot start with a hyphen."
	    exit -1
	fi
done

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
sourceFileExtension=$sourceFileExtension

if [ -z "$sa_path" ] ; then
    echo "Path sa_path not set as environment variable."
    exit -1
fi

# Some normalizations
# As the location in the supplied stagingfile is not absolute, but taken from the point of view of a ftp
# home directory, we need to make it absolute.
#
# Example:      FileSet =       /a/b/c/d
#               location =      /d/e/f
# must be       location =      /a/b/c/d/e/f
if [ ! -z "$location" ]; then
	location=$(dirname $fileSet)$location
	if [ -z "$l" ]; then
        	l=$location
	fi
	if [ -f "$l" ] ; then
		length=$(stat -c%s "$l")
	else
		length=0
	fi
fi

# Split the contentType [family/type] into two separate variables. Example:
# contentType = image/jpeg => derivative:image,sourceFileExtension=jpeg
if [ -z "$sourceFileExtension" ]; then
    sentence=${contentType//\//$' '}  # change the / to the separator white space
    i=0;
    for word in $sentence
        do
                a[$i]=$word;
                let i++;
        done
    derivative=${a[0]}
    sourceFileExtension=${a[1]}
fi

# Should the content NOT be a json string, we nullify it
if [ ${content:0:1} == "{" ]; then
	echo "Content: $content"
else
	content=null
fi

# If no webservice endpoint or key was given, we supply a custom value
if [ -z "$pidwebserviceEndpoint" ]; then
        pidwebserviceEndpoint=$endpoint
        pidwebserviceKey=$key
fi
if [ -z "$pidwebserviceKey" ]; then
        pidwebserviceEndpoint=$endpoint
        pidwebserviceKey=$key
fi

db="$database"_"$na"

statusCode=$statusCode
autoGeneratePIDs=$autoGeneratePIDs
name=$name
access=$access
action=$action
id=$id
resolverBaseUrl=$resolverBaseUrl
identifier=$identifier
instruction="{instruction:{workflow:{workflow:{name:'$name',statusCode:$statusCode, identifier:'$identifier'}},'fileSet':'$fileSet', \
    autoGeneratePIDs:'$autoGeneratePIDs',resolverBaseUrl:'$resolverBaseUrl',na:'$na',contentType:'$contentType', \
    access:'$access',action:'$action',id:'$id'}}"
