/**
 * add_shard.js
 *
 * Usage: mongo admin --eval "var database='or_12345'; var replset='replset'; var shardkey=12345" add_shard.js
 *
 * Prepares a new shard for the sharded environment.
 * See http://docs.mongodb.org/manual/administration/sharded-clusters/
 *
 * The shardkey is the same type in the key's: [ns].files._id and [ns].chunks.files_id
 */

assert(db.getName() == 'admin', 'The database is not the admin database. Connect to a mongos router specifying a production database: "mongo admin"');
assert(database.startsWith('or_'), 'The database should start with or_: var database=\'or_12345\'');
assert(replset) ;
assert(shardkey)  ;

var middle = { 'files_id' : shardkey };


var buckets = ['master', 'level1', 'level2', 'level3'];

for (var i = 0; i < buckets.length; i++) {

    var shardCollection = database + '.' + buckets[i] + '.chunks';

    // Pre splitting the chunks.
    print('split collection ' + shardCollection + ' with shardkey '); printjson(middle);
    db.runCommand({ split:shardCollection, middle:middle});

    // Move the chunk range from the primary shard to the targeted shards.
    print('moveChunk from collection ' + shardCollection + ' to shard ' + replset);
    db.runCommand({ moveChunk:shardCollection, find: middle, to:replset});
}
