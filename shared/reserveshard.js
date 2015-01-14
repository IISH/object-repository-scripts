/**
 reserveshard.js

 Before we write; we reserve this shard for ourselves ( the client ). This will lessen the change of other clients using
 the same shard as well to write to.

 and after we have written to the shard, we release the reservation.

 **/

assert(reserve !== undefined, 'Must have a reserve status: var reserve=true or false');
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(shardKey, 'Must have a shardKey: var shardKey=shardKey"');
var shards = db.candidate.findOne({_id:'shards'});
assert(shards, 'Must have a list of shard min keys defined');
delete shards._id;

for (shardId in shards) {
    if (shards.hasOwnProperty(shardId)) {
        var shard = shards[shardId];
        assert(shard.minKey, 'Missing minKey');
        assert(shard.interval, 'Missing interval');
        if (shardKey >= shard.minKey && shardKey < (shard.minKey + shard.interval)) {
            var _id = shardId + "_" + bucket;
            if (reserve) {
                db.candidate.save({_id:_id, d:new Date()});
            } else {
                db.candidate.remove({_id:_id});
            }
            break;
        }
    }
}