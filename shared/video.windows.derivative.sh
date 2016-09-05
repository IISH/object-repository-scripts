#!/bin/bash
#
# video.windows.derivative.sh
# Retrieve the source file and make a derivative
#
# This script will be run by cygwin.
# All linux posix file names refer to $derivative_cache
# $derivative_cache must be a mount to the windows filesystem set in fstab. E.g.


sa_path=$sa_path
scripts=$scripts
db=$db
pid=$pid
md5=$md5
sourceBuckets=$sourceBuckets
bucket=$bucket
tmp=$derivative_cache # E.g. "/cygdrive/d"
format=$format
targetFile="${tmp}/${md5}.${bucket}.${format}"
preset=$preset
mvccl_opts=$mvccl_opts

for sourceBucket in ${sourceBuckets[*]}
do
	echo "sourceBucket='$sourceBucket'"
    sourceFile=$tmp/$md5.$sourceBucket.bin
    echo "sourceFile=$sourceFile"
    if [ -f "$sourceFile" ]; then
	    echo "Using existing cached file on $sourceFile"
	    break
    else
	    l="$sourceFile"
	    source $scripts/shared/get.sh
	    if [ -f "$sourceFile" ] ; then
	        echo "Using db file on $sourceFile"
	        break
	    fi
    fi
done


# Run the convert script to create derivative.
windows_sourceFile="$(cygpath --windows $sourceFile)"
windows_targetFile="$(cygpath --windows $targetFile)"
if [ -f "$sourceFile" ]; then
	echo "Creating derivative from $sourceFile"
	echo "running: mvccl /file ${windows_sourceFile} /outputfile ${windows_targetFile} /preset $preset ${mvccl_opts}"
    mvccl /file "$windows_sourceFile" /outputfile "$windows_targetFile" /preset $preset "$mvccl_opts"
else
	echo "Could not find a master or higher level derivative to produce a $bucket file"
	echo "We need at least a master to produce a derivative."
	exit 240
fi

rc=$?
case $rc in
    1)
        echo "The program has been compromised."
        ;;
    2)
        echo "No such file or directory."
        ;;
    3)
        echo "Internal error."
        ;;
    4)
        echo "The preset has not been found."
        ;;
    5)
        echo "I/O error."
        ;;
    12)
        echo "Not enough memory."
         ;;
    22)
        echo "Invalid argument."
        ;;
    28)
        echo "No enough space on the hard drive."
        ;;
    29)
        echo "Conversion error. Fall back on ffmpeg."
        ffmpeg -i "$windows_sourceFile" -vcodec libx264 -preset slower -crf 23 -y "$windows_targetFile"
        rc=$?
        if [[ $rc != 0 ]] ; then
		    echo "Conversion error ${rc} from ffmpeg. Second attempt with audio channel reduction."
		    ffmpeg -i "$windows_sourceFile" -ac 2 -vcodec libx264 -preset slower -crf 23 -y "$windows_targetFile"
	    fi
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "ffmpeg failover did not work either. It gave an error response ${rc}."
        fi
        ;;
    30)
        echo "Invalid conversion settings."
        ;;
    31)
        echo "The conversion has been interrupted by the user."
        ;;
    32)
        echo "The trial period has been expired."
        ;;
    33)
        echo "Copy-protected DVD."
        ;;
    0)
        echo "mvccl conversion exited with an 'ok'"
        ;;
    *)
        echo "Warning. Unknown exit code: ${rc}"
        ;;
esac

rm "$sourceFile"
if [[ $rc != 0 ]] ; then
    rm "$targetFile"
    exit 1
fi

if [ -f "$targetFile" ]; then
	contentType="$targetContentType"
	l=$targetFile
	length=$(stat -c%s "$l")
	md5=$(md5sum $targetFile | cut -d ' ' -f 1)
	echo "$md5  $targetFile" > "$targetFile.md5"
	remove="yes"
	source $scripts/shared/put.sh
else
	echo "Unable to create derivative."
	exit 240
fi