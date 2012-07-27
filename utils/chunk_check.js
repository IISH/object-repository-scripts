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
var errors = 0;

filesCollection.find().forEach(function (file) {
    count++;
    //print(c + ". Check document " + file._id);
    var nc = Math.ceil(file.length / file.chunkSize);
    var chunks = chunksCollection.count({files_id:file._id, data:{$exists:true}});

    if (chunks != nc) {
        errors++;
        print(errors + ". _id:" + file._id + ",pid:" + file.metadata.pid + " found " + chunks + " chunks but expected " + nc);
        // find any gaps...
        for (var n = 0; n < nc; n++) {
            var chunk = chunksCollection.find({files_id:file._id, n:n}, {data:0});
            if (chunk.count == 0) {
                print("Chunk missing! n=" + n);
            }
            if (chunk.count > 1) {
                print("Found " + chunk.count + " chunks while there ought to be one only for n=" + n);
            }
        }
    }
})
print("Checked documents: " + count);
