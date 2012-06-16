/**
 * verify.js
 *
 * Check if the md5 and length returns the pid value.
 * Check if the amount of chunks are indeed as expected.
 *
 * Usage: mongo [database] --quiet --eval "var ... content parameters: ns, length, md5 and pid"
 **/

assert(ns, "Must have ns (bucket) as parameter.");
assert(length, "Must have length as parameter.");
assert(md5, "Must have md5 as parameter.");
assert(pid, "Must have pid as parameter.");

var query = {md5:md5,length:length};
var file = db.getCollection(ns + '.files').findOne(query);
assert(file, "Did not find a file with the expected md5 and length)");
assert(file.metadata.pid == pid, "The pid we find " + file.metadata.pid + " is not equal to the expected " + pid);

var count = db.getCollection(ns + '.chunks').count({files_id:file._id});
var countExpectedChunks = Math.ceil(length / file.chunkSize);
assert(count == countExpectedChunks, "There are chunks missing ! Expected " + countExpectedChunks + " but got " + count);
