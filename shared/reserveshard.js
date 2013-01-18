/**
 freeshard.js
 **/

assert(locked !== undefined, 'Must have a locked status: var locked=true or false');
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(shards, 'Must have a list of shard min keys defined: var shards="shards"');
assert(shardKey, 'Must have a shardKey: var shardKey=shardKey"');

var interval = 1431655765; // interval of a shard. The keys of a shard have range: [shard.minKey, shard.minKey+interval]

for (shardId in shards) {
    if (shards.hasOwnProperty(shardId)) {
        var minKey = shards[shardId].minKey;
        if (shardKey >= minKey && shardKey < (minKey + interval)) {
            var _id = shardId + "_" + bucket;
            if (locked) {
                db.candidate.save({_id:_id, d:new Date()});
            } else {
                db.candidate.remove({_id:_id});
            }
            break;
        }
    }
}