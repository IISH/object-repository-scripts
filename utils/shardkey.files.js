/**
 * Run this on each on the master's replicasets
 * This will retrieve all identifiers from the chunks collections
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(ns, "Need a namespace: var ns = 'ns'");

var files = db.getCollection(ns + ".files");
var chunks = db.getCollection(ns + ".chunks");
var interval = Math.round(4294967294 / (files.count() + 1));
var min = -2147483648;
var from = -2147483648 + Math.round(interval / 2);
var max = 2147483647;
var i = 0;
print("min=" + min);
print("max=" + max);
print("from=" + from);
print("interval=" + interval);
files.find().forEach(function (d) {
    if (d.old_id === undefined) {
        delete d.metadata.cache;
        d.old_id = d._id;
        var new_id = from + i++ * interval;
        assert(new_id > min || new_id < max, "The identifier is outside of the key's range: " + new_id);
        d._id = new_id;
        print("new_id=" + new_id);
        assert(d._id == new_id, "Identifiers do not match.");
        if (d.old_id.length != 48) {
            print("Warning: old key has not the expected length of 48 characters.");
        }
        files.save(d);
        files.remove({_id:d.old_id});
    }

    print('Update ' + d.old_id + ' with: ');
    var update = {$set:{files_id:d._id}};
    printjson(update);
    chunks.update({ files_id:d.old_id}, update, false, true);

    if ( ns == 'master' ) {
        cache(files, d.metadata.pid)
    }
})

/**
 * cache
 *
 * Copy all metadata elements of non-master related files into the master.files array
 *
 */
function cache(files, pid) {

    print("caching");

    var cache = [];
    var collectionNames = db.getCollectionNames();
    var length = collectionNames.length;
    for (var i = 0; i < length; i++) {
        var collectionName = collectionNames[i];
        if (collectionName.lastIndexOf(".files") != -1) {
            var bucket = db.getCollection(collectionName).findOne({'metadata.pid':pid});
            if (bucket) {
                if ('master.files' == collectionName) delete bucket.metadata.cache;
                bucket.metadata.pidUrl = 'http://hdl.handle.net/' + pid + '?locatt=view:' + bucket.metadata.bucket;
                cache.push(
                    bucket
                )
            }
        }
    }
    files.update({ 'metadata.pid':pid }, {$set:{'metadata.cache':cache}}, true, false);
}