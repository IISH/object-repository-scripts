/**
 * Change the primary keys via updates.
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(ns, "Need a ns");
assert(new_id, "Need an new_id");
assert(!isNaN(new_id), "new_id must be a number");
assert(old_id, "Need a old_id");
assert(isNaN(old_id), "old_id must be a string");
assert(pid, "Need a pid");

var files = db.getCollection(ns + ".files");
var master = files.findOne({'metadata.pid':pid});
assert(master, 'The document is not found!');
if (master._id == old_id) {
    assert(files.findOne({_id:new_id}) == null, "The new_id is already taken.");
    changeKeys(master);
    print('Done');
} else if (master._id == new_id) {
    print("The document is already converted.");
} else {
    print("The document was updated with _id:" + master._id);
};

function changeKeys(master) {
    var chunks = db.getCollection(ns + ".chunks");
    var nc = Math.ceil(master.length / master.chunkSize);
    print("Copy and save " + nc + " chunks: " + old_id + " to " + new_id);
    var moved = 0;
    for (var n = 0; n < nc; n++) {
        var file = chunks.findOne({files_id:old_id, n:n});
        if (file) {
            delete file._id;
            file.files_id = new_id;
            chunks.save(file);
            if (!writeOk(db)) {
                if (db.getLastError().startsWith('E11000')) { // We can ignore a duplicate key in case we like to repeat the insert.
                    print('Ignoring duplicate key error E11000... skipping copy');
                } else {
                    throw "Stopping because of the last error when invoking: chunks.save(file)";
                }
            }
            moved++;
        }
    }

    if ( moved == 0 ) print("Warn: there were no chunks found to move to the new identifier.");

    var countNewChunks = chunks.count({files_id:new_id});
    assert(countNewChunks == nc, "Chunk count not correct. Was " + countNewChunks + " but expect: " + nc);

    // As we confirmed each chunk insert, we remove the old ones.
    chunks.remove({files_id:old_id});
    assert(writeOk(db), "chunks.remove({files_id:old_id})");

    // Finally we update the master document.
    files.remove({_id:old_id});
    assert(writeOk(db), "files.remove({_id:old_id})");
    master._id = new_id;
    files.save(master);
    assert(writeOk(db), "files.save(master)");
}

function writeOk(db) {
    var lastError = db.getLastError("majority"); // waits for more than 50% of the members to acknowledge the write (until replication is applied to the point of that write).
    if (lastError) {
        print("Error:");
        print("old_id:" + old_id);
        print("new_id:" + new_id);
        printjson(lastError);
        return false;
    }
    return true;
}

