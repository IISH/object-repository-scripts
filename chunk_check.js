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


var collectionNames = db.getCollectionNames();
var length = collectionNames.length;
for (var i = 0; i < length; i++) {
    var collectionName = collectionNames[i];
    var index = collectionName.lastIndexOf(".files");
    if (index != -1) {
        print("Begin check FSGrid collection " + collectionName);
        var namespace = collectionName.substring(0, index);
        var filesCollection = db.getCollection(namespace + '.files');
        var chunksCollection = db.getCollection(namespace + '.chunks');

        var count = 0;
        filesCollection.find().forEach(function (file) {
            count++;
            //print(c + ". Check document " + file._id);
            var nc = Math.ceil(length / file.chunkSize);
            for (var n = 0; n <= nc; n++) {
                var chunk = chunksCollection.findOne({files_id:file._id, n:n, data:{$exists:true}}, {data:0});
                if (n == nc) {
                    if (chunk) {
                        print(file._id + " = corrupt document. There are too many chunks !");
                    }
                } else {
                    if (!chunk) {
                        print(file._id + " = corrupt document. Chunks are missing! n=" + n);
                    }
                }
            }
        });
        print("Checked documents: " + count);
    }
}