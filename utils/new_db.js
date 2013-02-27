/**
 * setup.js
 *
 * Usage: mongo host database
 *
 * Prepares a database for the sharded environment.
 * See http://www.mongodb.org/display/DOCS/Configuring+Sharding
 *
 * The shardkey is the same value in the key's: [ns].files.id and [ns].chunks.files_id
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(shards, "Must have the shard key ranges defined for presplitting: var shards={shardId:{p:'primary',minKey:[key]}, ...}");

// Shard database
var admin = db.getMongo().getDB("admin");
admin.runCommand("flushRouterConfig");
admin.runCommand({ enablesharding:db.getName() });

// The shard key is a Javascript number


var buckets = ['master', 'level1', 'level2', 'level3'];
for (var i = 0; i < buckets.length; i++) {
    var collFiles = buckets[i] + ".files";
    var collChunks = buckets[i] + ".chunks";

    // Add index
    db.getCollection(collChunks).ensureIndex({files_id:1, n:1}, {unique:true});
    db.getCollection(collFiles).ensureIndex({'metadata.pid':1}, {unique:true});
    db.getCollection(collFiles).ensureIndex({'metadata.label':1}, {unique:false});
    db.getCollection(collFiles).ensureIndex({'metadata.objid':1}, {unique:false});

    // Shard collection
    var shardThis = db.getName() + "." + collChunks;
    admin.runCommand({ shardcollection:shardThis, key:{ files_id:1 }, unique:false});

    // Pre splitting the chunks over the shard.
    for (var shardId in shards) {
        if (shards.hasOwnProperty(shardId)) {
            var shard = shards[shardId];
            print('split collection ' + shardThis + ' with shardkey  + shard.minKey');
            admin.runCommand({ split:shardThis, middle:{ files_id:shard.minKey} });
        }
    }

    for (shardId in shards) {
        if (shards.hasOwnProperty(shardId)) {
            shard = shards[shardId];
            print('moveChunk from collection ' + shardThis + ' with shardkey ' + shard.minKey + ' to shard ' + shardId);
            db.runCommand({ moveChunk:shardThis, find:{ files_id:shard.minKey }, to:shardId});
        }
    }
}

print('Use db.printShardingStatus() to see the shard status.');
