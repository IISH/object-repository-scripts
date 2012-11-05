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


// Shard database
var admin = db.getMongo().getDB("admin");
admin.runCommand("flushRouterConfig");
admin.runCommand({ enablesharding:db.getName() });

// The shard key is a integer of 32 bit over three ( purely an arbitrary choice )
// shard 0: [-2147483648, -715827884] = 1431655765
// shard 1: [ -715827883,  715827882] = 1431655765
// shard 2: [  715827883, 2147483647] = 1431655765
// shard 3: [ 2147483648, 3579139412] = 1431655765
var keys = [-715827883, 715827882];
var buckets = ['master', 'level1', 'level2', 'level3'];
for (var i = 0; i < buckets.length; i++) {
    var collFiles = buckets[i] + ".files";
    var collChunks = buckets[i] + ".chunks";

    // Add index
    db.getCollection(collChunks).ensureIndex({files_id:1, n:1}, {unique:true});
    db.getCollection(collFiles).ensureIndex({'metadata.pid':1}, {unique:true});

    // Shard collection
    var shardThis = db.getName() + "." + collChunks;
    admin.runCommand({ shardcollection:shardThis, key:{ files_id:1 }, unique:false});

    // Pre splitting the chunks over the shard. For each shard we have a key range: shards=[n]; keys=[n-1].
    for (var k = 0; k < keys.length; k++) {
        var key = keys[k];
        print("split collection " + shardThis + " with shardkey " + key);
        admin.runCommand({ split:shardThis, middle:{ files_id:key} });
    }

    for (k = 0; k < keys.length; k++) {
        key = keys[k];
        var shard = "rs_or" + (k + 1);
        print("moveChunk from collection " + shardThis + " with shardkey " + key + " to shard " + shard);
        admin.runCommand({ moveChunk:shardThis, find:{ files_id:key }, to:shard })
    }
}

print(db.printShardingStatus());
