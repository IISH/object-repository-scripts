/**
 * setup.js
 *
 * Usage: mongo host database
 *
 * Prepares a database for the sharded environment.
 * See http://www.mongodb.org/display/DOCS/Configuring+Sharding
 *
 * In our environment we use the String(md5)+HexLong(length) as a shardkey. Its range is between:
 * minKey = 00000000000000000000000000000000 0000000000000000
 * maxKey = ffffffffffffffffffffffffffffffff 7fffffffffffffff
 * It is the same value in the key's: [ns].files.id and [ns].chunks.files_id
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");


// Shard database
var admin = db.getMongo().getDB("admin");
admin.runCommand("flushRouterConfig");
admin.runCommand({ enablesharding:db.getName() });

// The shard key is
var keys = ['555555555555555555555555555555555555555555555555', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'];
var buckets = ['master', 'level1', 'level2', 'level3'];
for (var i = 0; i < buckets.length; i++) {
    var collChunks = buckets[i] + ".chunks";
    var collFiles = buckets[i] + ".files";

    // Add index
    db.getCollection(collChunks).ensureIndex( {files_id:1}, {unique:false} );
    db.getCollection(collFiles).ensureIndex( {md5:1, length:1}, {unique:true} );
    db.getCollection(collFiles).ensureIndex( {'metadata.pid':1}, {unique:false} ); // Yes false...

    // Shard collection
    var shardThis = db.getName() + "." + collChunks;
    admin.runCommand({ shardcollection:shardThis, key:{ files_id:1 }, unique:false});

    // Pre splitting the chunks over the shard. For each shard we have a key range: shards=[n]; keys=[n-1].
    for (var k = 0; k < keys.length; k++) {
        var key = keys[k];
        assert(key.length == 48, "Key's " + key + " radix must be 24");
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

// Ensure an index on the non sharded files collection also
db.getCollection('files').ensureIndex({pid:1}, { unique:true });

print(db.printShardingStatus());
