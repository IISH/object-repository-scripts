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
assert(ns, "Must have collection name: var ns='[ns]'");
assert(_id, "Must have _id name: var _id='[_id]'");

var doc = db.getCollection(ns + '.files').findOne({ _id: _id}, {length: 1, chunkSize: 1});
assert(doc, "Cannot find document with _id " + _id);

var nc = Math.ceil(doc.length / doc.chunkSize);
var count = 0;
var chunksCollection = db.getCollection(ns + '.chunks');
for (var n = 0; n < nc; n++) {
    if (chunksCollection.findOne({files_id: _id, n: n}, {_id: 1})) count++; // We use a findOne and not a count method so we actually hit the collection.
}

// return the id with the expected count; actual acount, and if these are the same or not.
print(_id + ' ' + nc + ' ' + count + ' ' + count == nc);
