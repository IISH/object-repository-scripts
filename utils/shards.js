/**
 * shards.js
 *
 * Generates shard ranges for the chunks collection based on the predefined and static shardkey and shard name.
 */

assert(db.getName() == 'config', "The database must be the config database: 'mongo host/config'");
assert(db, "Need a database name: var db='name here'");
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(shards, 'Must have a list of shard min keys defined: var shards="shards"');

for (shardId in shards) {
    if (shards.hasOwnProperty(shardId)) {
        var shard = stats.shards[shardId];
    }
}

