assert(_id, "Must have an _id");
assert(new_id, "Must have a new_id");
assert(nc, "Must have a count");
assert(host, "Must have a host");

assert(db.master.files.findOne({_id:new_id}) == null, "Key is already in use");
assert(db.master.chunks.findOne({files_id:new_id}) == null, "Key is already in use");

var doc = db.master.files.findOne({_id:_id});
assert(doc, "Could not find metadata");

delete doc._id;
db.master.files.remove({_id:_id});
assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not remove metadata.");

doc._id = new_id;
db.master.files.save(doc);
assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not save metadata.");

primary = connect(host + '/or_10622');
primary.master.chunks.update({files_id:_id}, {$set:{files_id:new_id}}, false, true);
assert(primary.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not update chunk files_id.");

for (var n = 0; n < nc; n++) {
    var count = db.master.chunks.count({files_id:new_id, n:n});
    if (count == 0) {
        throw "Chunk missing! n=" + n;
    }
    if (count > 1) {
        throw "Found " + count + " chunks while there ought to be one only for n=" + n;
    }
}
print("All chunks accounted for.");