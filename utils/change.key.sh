scripts=$scripts
ns=master
old_id=$1
new_id=$2
pid=$3

# Make sure all primaries are running on the expected hosts.
for primary in rosaluxemburg0 rosaluxemburg2 rosaluxemburg4
do
    host=$primary.objectrepository.org:27018
    ismaster=$(mongo $host --quiet --eval "db.serverStatus().repl.ismaster")
    if [ ! "$ismaster" = "true" ] ; then
        echo "$host is not primary; {db.serverStatus().repl.ismaster:$ismaster)"
        exit -1
    fi
done

# Make sure all secondaries are running on the expected hosts.
for secondary in rosaluxemburg1 rosaluxemburg3 rosaluxemburg5
do
    host=$secondary.objectrepository.org:27018
    issecondary=$(mongo $host --quiet --eval "db.serverStatus().repl.secondary")
    if [ ! "$issecondary" = "true" ] ; then
        echo "$host is not secondary; {db.serverStatus().repl.secondary:$issecondary)"
        exit -1
    fi
done

evl="var ns='$ns'; var old_id='$old_id'; var new_id=$new_id; var pid='$pid';"
echo $evl >> change.key.log
mongo or_10622 --quiet --eval "$evl" $scripts/utils/change.key.js >> change.key.log

rc=$?
if [[ $rc != 0 ]] ; then
    echo "mongo command did not return a clean exit value."
    exit $rc
fi

sleep 30
