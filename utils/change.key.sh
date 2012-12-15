scripts=$scripts
shards=$shards
db=or_10622
bucket=master
_id=$1
pid=$2

new_id=$(mongo $db --quiet --eval "var bucket='$bucket'; var shards=$shards" $scripts/shared/shardkey.js)
if [[ $new_id == 0 ]] ; then
    echo "Shardkey is zero." >> change.key.log
    exit -1
fi

for host in rosaluxemburg1 rosaluxemburg7 rosaluxemburg5
do
    secondary=$(mongo $host:27018/test --quiet --eval "db.serverStatus().repl.secondary")
    if [ ! "$secondary" == "true" ] ; then
        echo "$host is not a secondary">>change.key.log
        exit -1
    fi
done

evl="var bucket='$bucket'; var old_id='$_id'; var new_id=$new_id; var pid='$pid';"
echo $evl >> change.key.log
mongo $db --quiet --eval "$evl" $scripts/utils/change.key.js >> change.key.log

rc=$?
if [[ $rc != 0 ]] ; then
    echo "mongo command did not return a clean exit value." >> change.key.log
    exit $rc
fi