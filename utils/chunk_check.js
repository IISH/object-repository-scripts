/**
 * chunk_check.js
 *
 * Usage: mongo host database
 *
 * Iterates over each gridFS collection.
 * For each files document it counts and checks to see if it can find the chunk.
 *
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(bucket, "Must have collection name: var bucket='[bucket]'");
assert(_id, "Must have _id name: var _id='[_id]'");
assert(host, "Must have host name of a replicaset member: var host='[host]'");

var files_id = NumberLong(_id);
var doc = db.getCollection(bucket + '.files').findOne({ _id: files_id}, {length: 1, chunkSize: 1});
assert(doc, "Cannot find document with _id " + _id);


// Now connect to the server we want to check.
var server = connect(host + db.getName());
server.getMongo().setSlaveOk();


var chunksCollection = server.getCollection(bucket + '.chunks');
var nc = Math.ceil(doc.length / doc.chunkSize);
for (var n = 0; n < nc; n++) {
    var chunk = chunksCollection.findOne({files_id: files_id, n: n}, {_id: 0, md5:1, data:1});
    print('"' + host + '","' + chunk.md5 + '","' + chunk.data.hex() + '"');
}