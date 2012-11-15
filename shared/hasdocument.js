/**
 * hasdocument.js
 *
 * Checks if all chunks are accounted for.
 *
 */

assert(bucket, "Must have a bucket value.");
assert(pid, "Must have a pid value.");

var ret = false;

var file = db.getCollection(bucket + ".files").findOne({'metadata.pid':pid}, {_id:1, chunkSize:1, length:1, 'metadata.access':1});
if (file && file.metadata.access) {
    var expect = Math.ceil(file.length / file.chunkSize);
    var count = db.getCollection(bucket + ".chunks").count({files_id:file._id});
    ret = ( expect == count );
}

print(ret);
