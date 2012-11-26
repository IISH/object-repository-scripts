/**
 * Change the primary keys via updates.
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(bucket, "Need a bucket");
assert(new_id, "Need an new_id");
assert(!isNaN(new_id), "new_id must be a number");
assert(new_id != 0, "new_id must not be zero.");
assert(old_id, "Need a old_id");
assert(pid, "Need a pid");

var start = new Date();
var files = db.getCollection(bucket + ".files");
var master = files.findOne({'metadata.pid':pid});

if (master == null) {
    print('The document is not found. It may have been removed.');
} else if (master._id == old_id) {
    assert(files.findOne({_id:new_id}) == null, "The new_id is already taken.");
    changeKeys(master);
    var end = new Date();
    print('Done in ' + (end.getTime() - start.getTime()) / 1000 + ' seconds.');
} else {
    assert(!isNaN(master._id), "The _id found is not a number.");
    print("The document is already converted and has _id: " + master._id);
}

function changeKeys(master) {

    // Reserve the key
    files.save({_id:new_id});
    assert(writeOk(db), "Key could not be saved.");

    var chunks = db.getCollection(bucket + ".chunks");
    var nc = Math.ceil(master.length / master.chunkSize);
    print("Copy and save " + nc + " chunks: " + old_id + " to " + new_id);
    var moved = 0;

    db.resetError();
    for (var n = 0; n < nc; n++) {
        var file = chunks.findOne({files_id:old_id, n:n});
        if (file) {
            delete file._id;
            file.files_id = new_id;
            chunks.save(file);
            moved++;
        }
    }

    if (db.getPrevError().err) {
        print("Error with chunks.save(file);");
        printjson(db.getPrevError());
        throw "The operation should be undone by removing all files_id:" + new_id + " from " + chunks.getName();
    }

    assert(writeOk(db), "Error after batch files_id update");

    // In some cases the documents are still being processed... hence we retry after 60 seconds.
    var countNewChunks = chunks.count({files_id:new_id});
    if (countNewChunks != nc) sleep(60000);
    countNewChunks = chunks.count({files_id:new_id});
    assert(countNewChunks == nc, "Chunk count not correct. Was " + countNewChunks + " but expect " + nc + " " +
        "The operation should be undone by removing all files_id:" + new_id + " from " + chunks.getName());

    // As we confirmed each chunk insert, we remove the old ones.
    chunks.remove({files_id:old_id});
    assert(writeOk(db), "chunks.remove({files_id:" + old_id + "})");

    // Finally we update the master document.
    files.remove({_id:old_id});
    assert(writeOk(db), "files.remove({_id:" + old_id + "})");
    master._id = new_id;
    files.save(master);
    assert(writeOk(db), "files.save(master)");
}

function writeOk(db) {
    var lastError = db.runCommand({getlasterror:1, j:true}); // waits for the journal to flush.
    if (lastError && lastError.value) {
        print("Error: ");
        print("old_id:" + old_id);
        print("new_id:" + new_id);
        print("pid:" + pid);
        printjson(lastError.value);
        return false;
    }
    return true;
}

