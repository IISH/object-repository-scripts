/**
 * verify.js
 *
 * Check if the md5 and length returns the pid value.
 * Check if the amount of chunks are indeed as expected.
 *
 * Usage: mongo [database] --quiet --eval "var ... content parameters: ns, length, md5 and pid"
 **/

assert(ns, "Must have ns (bucket) as parameter.");
assert(md5, "Must have md5 as parameter.");
assert(pid, "Must have pid as parameter.");

// First a normalization. The md5 in the mongodb collection is always 32 characters in length
md5 = "00000000000000000000000000000000" + md5;
md5 = md5.substring(md5.length - 32);

var query = {'metadata.pid':pid, md5:md5};
var filesCollection = db.getCollection(ns + '.files');
var file = filesCollection.findOne(query);
assert(file, "Did not find a file with the expected md5");
assert(file.length, "Did not find a file with the expected length element");


// Paranoid check each chunk
var nc = Math.ceil(file.length / file.chunkSize);
var chunkCollection = db.getCollection(ns + '.chunks');
for (var n = 0; n <= nc; n++) {
    var chunk = chunkCollection.findOne({files_id:file._id, n:n}, {data:0});
    if (n == nc) {
        if (chunk) {
            removeDocument(filesCollection, chunkCollection, file._id)
            throw "Removing corrupt document. There are too many chunks !";
        }
    } else {
        if (!chunk) {
            removeDocument(filesCollection, chunkCollection, file._id)
            throw "Removing corrupt document. There are chunks missing ! Chunk n:" + n;
        }
    }
}

/**
 * removeDocument
 *
 * Removes a document and it's chunks
 *
 * @param document
 */
function removeDocument(filesCollection, chunkCollection, _id) {

    filesCollection.remove({_id:_id});
    chunkCollection.remove({files_id:_id});
}


