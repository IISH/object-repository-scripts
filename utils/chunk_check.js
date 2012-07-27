/**
 * chunk_check.js
 *
 * Usage: mongo host database
 *
 * Iterates over each gridFS collection.
 * For each files document it counts and checks to see if it can finds the chunk.
 *
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(collection, "Must have collection name: [ns].files");
var index = collection.lastIndexOf(".files");
assert(index != -1, "Collections must be [ns].files");

print("Begin check FSGrid collection " + collection);
var namespace = collection.substring(0, index);
var filesCollection = db.getCollection(namespace + '.files');
var chunksCollection = db.getCollection(namespace + '.chunks');

var count = 0;
filesCollection.find().forEach(function (file) {
    count++;
    //print(c + ". Check document " + file._id);
    var nc = Math.ceil(file.length / file.chunkSize);
    for (var n = 0; n <= nc; n++) {
        var chunk = chunksCollection.findOne({files_id:file._id, n:n, data:{$exists:true}}, {data:0});
        if (n == nc) {
            if (chunk) {
                print(file._id + " = corrupt document. There are too many chunks ! Expected " + nc + " but got " + n);
            }
        } else {
            if (!chunk) {
                print(file._id + " = corrupt document. Chunks are missing! n=" + n);
            }
        }
    }
});
print("Checked documents: " + count);