/**
 * add_shard.js
 *
 * Usage: add a new shard with collections and shard settings
 * Eg: mongo or_12345 --eval "var replset='replset'; var shardkey=12345" add_shard.js
 *
 * Prepares a new shard for the sharded environment.
 * See http://docs.mongodb.org/manual/administration/sharded-clusters/
 *
 * The shardkey is the same type in the key's: [ns].files._id and [ns].chunks.files_id
 */

assert(db.getName() != 'test', 'The database is the test database. Startup specifying a production database: "mongo host/database"');
assert(replset) ;
assert(shardkey)  ;


var admin_db = db.getMongo().getDB('admin');
var buckets = ['master', 'level1', 'level2', 'level3'];
for (var i = 0; i < buckets.length; i++) {
    
    var shardCollection = db.getName() + '.' + buckets[i] + '.chunks';

    // Pre splitting the chunks.
    print('split collection ' + shardCollection + ' with shardkey  ' + shardkey);
    admin_db.runCommand({ split:shardCollection, middle:{ shardkey:shardkey} });

    // Move the chunk range from the primary shard to the targeted shards.
    print('moveChunk from collection ' + shardCollection + ' with shardkey ' + shardkey + ' to shard ' + replset);
    admin_db.runCommand({ moveChunk:shardCollection, find:{ shardkey:shardkey }, to:replset});
}
