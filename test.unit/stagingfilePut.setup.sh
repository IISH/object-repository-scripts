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
na=12345
testuser="testuser"
folder="unittest"
fileSet=$sa_path/$na/$testuser/$folder
source $scripts/shared/parameters.sh
db=$db
make=$make
manual=$manual
echo "Add '-make database' to reconstruct a template with test material."
echo "fileSet=$fileSet"
echo "db=$db"

if [ ! "or_12345" == "$db" ]; then
 echo "Error... running a test with na=$na the test na MUST be 12345"
 exit -1
fi

if [ "$make" == "database" ]; then

    echo "Reconsructing files and database."

    # Begin with an empty database... we call them buckets, but they are really namespaces
    mongo $db --eval "printjson(db.dropDatabase())"

    mkdir -p $fileSet
    rm -f $fileSet/*.txt
    rm -f $fileSet/*.md5

    counter=0
    for bucket in "master" "level1" "level2" "level3"
    do
        mongo $db --quiet --eval "db.getCollection('$bucket.files').ensureIndex({md5:1,length:1}, {unique:true})"
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
                    let "counter++"
                fi
            done
        done
    done
    echo "Added $counter files in four collections"

    # We now ought to have buckets * i * j files
    checkCounter=0
    for bucket in "master" "level1" "level2" "level3"
    do
        c=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').count()")
        let "checkCounter+=$c"
    done
    if [ "$checkCounter" != "$counter" ]; then
        echo "Expected a count of $counter but actually found $checkCounter"
    fi

    #  File count is as expected
    mongo test --eval "printjson(db.dropDatabase())"
    mongo $db --quiet --eval "printjson(db.copyDatabase('$db', 'test'))"
fi

mongo $db --quiet --eval "db.dropDatabase();printjson(db.copyDatabase('test', '$db'))"

