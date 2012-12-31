/**
 * shards.js
 *
 * See if the position of the documents are indeed in the expected range.
 */

assert(db, "Need a database name: var db='name here'");
assert(ns, 'Must have a bucket namespace defined: var bucket="?.chunks"');
assert(ns.indexOf('.chunks') > 0, 'Must have a bucket namespace defined: var bucket="?.chunks"');
assert(shards, 'Must have a list of shard min keys defined: var shards="shards"');

var interval = 1431655765; // interval of a shard. The keys of a shard have range: [shard.minKey, shard.minKey+interval]

for (shardId in shards) {
    if (shards.hasOwnProperty(shardId)) {
        var shard = shards[shardId];
        var secondary = connect(shard.s + '/' + db);
        secondary.getMongo().setSlaveOk();

        var collection = secondary.getCollection(ns);
        var countActual = collection.count();
        var countShouldHave = collection.count({files_id:{$gte:shard.minKey}, files_id:{$lt:shard.minKey + interval}});

        print(shard.s + '\\' + db + ' ' + ns + ' ' + countActual + ' ' + countShouldHave + ' ' + (countActual == countShouldHave));
    }
}
