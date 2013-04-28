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
assert(paranoid, "Must have paranoid as parameter.");

// First a normalization. The md5 in the mongodb collection is always 32 characters in length
md5 = "00000000000000000000000000000000" + md5;
md5 = md5.substring(md5.length - 32);

var query = {'metadata.pid': pid, md5: md5};
var filesCollection = db.getCollection(ns + '.files');
var file = filesCollection.findOne(query);
assert(file, "Did not find a file with the expected md5");
assert(file.length, "Did not find a file with the expected length element");

var nc = Math.ceil(file.length / file.chunkSize);
var chunkCollection = db.getCollection(ns + '.chunks');
var count = chunkCollection.count({files_id: file._id});
assert(count == nc, "Counted " + count + ' chunks, but expected ' + nc);

// Paranoid check each chunk. This way we do not look at an index.
if (paranoid) {
    for (var n = 0; n < nc; n++) {
        var chunk = chunkCollection.findOne({files_id: file._id, n: n}, {data: 0});
        assert(chunk, "There are chunks missing ! Chunk n:" + n);
    }
}



