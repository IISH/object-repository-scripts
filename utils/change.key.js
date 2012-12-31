var host="rosaluxemburg4:27018";
var start = new Date();

assert(_id, "Must have an _id");
assert(new_id, "Must have a new_id");
var nc=db.level2.chunks.count({files_id:_id});

assert( nc > 0, "No chunks found!") ;

var doc = db.level2.files.findOne({_id:_id});
if (doc == null) {
    assert(db.level2.files.findOne({_id:new_id}), "Cannot find document with old or new key !");
} else {

    assert(db.level2.files.findOne({_id:new_id}) == null, "Key is already in use");
    assert(db.level2.chunks.findOne({files_id:new_id}) == null, "Key is already in use");

    delete doc._id;
    db.level2.files.remove({_id:_id});
    assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not remove metadata.");

    doc._id = new_id;
    db.level2.files.save(doc);
    assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not save metadata.");
}

primary = connect(host + '/or_10622');
primary.level2.chunks.update({files_id:_id}, {$set:{files_id:new_id}}, false, true);
assert(primary.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not update chunk files_id.");

var count=db.level2.chunks.count({files_id:new_id});
assert(count==nc, "Found " + count + " chunks, but expect " + nc);

var end = new Date();
print(count + " chunks accounted for " + host + ":" + new_id + " in " + (end.getTime() - start.getTime()) / 1000 + " seconds.");