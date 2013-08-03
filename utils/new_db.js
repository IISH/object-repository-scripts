/**
 * new_db.js
 *
 * Usage: add a new database with collections and shard settings
 *
 * Prepares a database for the sharded environment.
 * See http://www.mongodb.org/display/DOCS/Configuring+Sharding
 *
 * The shardkey is the same value in the key's: [ns].files._id and [ns].chunks.files_id
 */

assert(db.getName() != 'test', 'The database is the test database. Startup specifying a production database: "mongo host/database"');
assert(shards, 'Must have the shard key ranges defined for presplitting: var shards={shardId:{p:"primary",minKey:[key]}, ...}');

// Shard database
var admin = db.getMongo().getDB('admin');
admin.runCommand('flushRouterConfig');
admin.runCommand({ enablesharding:db.getName() });

// The shard key is a Javascript number

var buckets = ['master', 'level1', 'level2', 'level3'];
for (var i = 0; i < buckets.length; i++) {
    var collFiles = buckets[i] + '.files';
    var collChunks = buckets[i] + '.chunks';

    // Add index
    db.getCollection(collChunks).ensureIndex({files_id:1, n:1}, {unique:true});
    db.getCollection(collFiles).ensureIndex({'metadata.pid':1}, {unique:true});
    db.getCollection(collFiles).ensureIndex({'metadata.label':1}, {unique:false});
    db.getCollection(collFiles).ensureIndex({'metadata.objid':1,'metadata.seq':1}, {unique:false});

    // Shard collections
    //shard(db.getName() + '.' + collFiles, '_id');
    shard(db.getName() + '.' + collChunks, 'files_id');
}

// Add the siteusage collection
db.createCollection('siteusage', { capped:true, size: 43200000 } );

function shard(shardcollection, shardKey) {
    var key = {};
    key[shardKey] = 1 ;
    admin.runCommand({ shardcollection:shardcollection, key:key, unique:false});

    // Pre splitting the chunks over the shard.
    for (var shardId in shards) {
        if (shards.hasOwnProperty(shardId)) {
            var shard = shards[shardId];
            print('split collection ' + shardcollection + ' with shardkey  ' + shard.minKey);
            admin.runCommand({ split:shardcollection, middle:{ shardKey:shard.minKey} });
        }
    }

    for (shardId in shards) {
        if (shards.hasOwnProperty(shardId)) {
            shard = shards[shardId];
            print('moveChunk from collection ' + shardcollection + ' with shardkey ' + shard.minKey + ' to shard ' + shardId);
            db.runCommand({ moveChunk:shardcollection, find:{ shardKey:shard.minKey }, to:shardId});
        }
    }
}

print('Use db.printShardingStatus() to see the shard status.');
