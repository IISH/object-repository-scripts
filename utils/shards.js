/**
 * shards.js
 *
 * Generates shard ranges for the chunks collection based on the predefined and static shardkey and shard name.
 */

assert(db.getName() == 'config', "The database must be the config database: 'mongo host/config'");
assert(db, "Need a database name: var db='name here'");
assert(bucket, 'Must have a bucket namespace defined: var bucket="?.chunks"');
assert(bucket.indexOf('.chunks') > 0, 'Must have a bucket namespace defined: var bucket="?.chunks"');
assert(shards, 'Must have a list of shard min keys defined: var shards="shards"');

var ns = db + '.' + bucket;
var lastmodEpoch = new ObjectId();

var length = Object.keySet(shards).length;
for (var i = 0; i < length; i++) {

    var shardId = Object.keySet(shards)[i];

    var chunk = {
        _id:ns + '-files_id_' + (i == 0) ? 'MinKey' : shards[shardId].minKey + '.0',
        "lastmod":Timestamp(1000, i),
        "lastmodEpoch":lastmodEpoch,
        "ns":ns,
        "min":(i == 0) ? { $minKey:1 } : shards[shardId].minKey + '.0',
        "max":(i == length - 1) ? { $maxKey:1 } : shards[Object.keySet(shards)[i + i]].minKey + '.0',
        "shard":shardId
    };

    db.chunks.save(chunk);
}
