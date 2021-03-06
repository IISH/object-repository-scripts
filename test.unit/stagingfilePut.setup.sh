#
# /StagingfileIngestMaster/test/stagingfilePut.instructionSetup.sh
#
# Purpose is to make sure the add and update procedures work well as described
# in /shared/put.js
#
# Use stagingfilePut.case2.sh make to reconstruct the database and testfiles

sa_path=$sa_path
scripts=$scripts
orfiles=$orfiles
na="12345"
testuser="testuser"
folder="unittest"
fileSet=$sa_path/$na/$testuser/$folder
source $scripts/shared/parameters.sh
db=$db
make=$make
manual=$manual
echo "fileSet=$fileSet"
echo "db=$db"

if [ ! "or_12345" == "$db" ]; then
 echo "Error... running a test with na=$na the test na MUST be 12345"
 exit -1
fi

    echo "Reconsructing files and database."

    mkdir -p $fileSet
    rm $fileSet/*.txt
    rm $fileSet/*.md5

    counter=0
    for bucket in "master" "level1" "level2" "level3"
    do
	
	# mongo $db --quiet --eval "db.getCollection('$bucket.files').remove()"
    # mongo $db --quiet --eval "db.getCollection('$bucket.chunks').remove()"
        for i in 0 1 2 3
        do
            for j in 0 1 2
            do
            filename=$bucket.$i.$j.txt
                file="$fileSet/$filename"
                echo $file > $file
                if [ $i != 3 ]; then
            location=/$folder/$filename
                    md5=$(md5sum $file | cut -d ' ' -f 1)
                    pid=$na/$i.$j
                    $scripts/shared/put.sh -na $na -bucket $bucket -contentType "image/jpeg" -pid $pid \
                        -md5 $md5 -location $location -access "open" -label "test label $md5" -fileSet $fileSet
                    let counter++
                fi
            done
        done
    done
    echo "Added $counter files in four collections"

    # We now ought to have buckets * i * j files
    checkFilesCounter=0
    checkChunksCounter=0
    for bucket in "master" "level1" "level2" "level3"
    do
        cFiles=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').count()")
	    cChunks=$(mongo $db --quiet --eval "db.getCollection('$bucket.chunks').count()")
        let checkFilesCounter+=$cFiles
	    let checkChunksCounter+=$cChunks
    done
    if [ $checkFilesCounter != $counter ]; then
        echo "Expected a count of $counter but actually found $checkFilesCounter"
	exit -1
    fi

    if [ $checkChunksCounter != $counter ]; then
        echo "Expected a count of $counter but actually found $checkChunksCounter"
	exit -1
    fi

echo "=================================================================================================================="
