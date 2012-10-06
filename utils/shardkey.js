/**
 * Run this on each on the master's replicasets
 * This will retrieve all identifiers from the chunks collections
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(ns, "Need a namespace: var ns = 'ns'");
assert(count, "Need total files count: var count = count");
assert(index, "Need starting index: var index = index"); // 0 for shard 0; count for shard 1; count + count for shard 1 and 2
assert(shard, "Need shard number: var shard = shard"); // 0 for shard 0; count for shard 1; count + count for shard 1 and 2

var bucket = db.getCollection(ns + ".chunks");
var interval = Math.round(4294967294 / count); // total amount of possible values in a Integer32
var min = -2147483648 + Math.round(interval / 2);
bucket.find({}, {files_id:1, _id:0}).forEach(function (doc) {
    var i = min + index++ * interval;
    print(i + ' ' + doc.files_id + ' ' + shard + ' ' + db.getName() + ' ' + ns);
})


