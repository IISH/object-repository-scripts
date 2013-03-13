/**
 recreate.js

 Take all metadata from the master files into a instruction
 **/

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(na, "Need a naming authority");
assert(id, "Must have a id: var id='?'");
assert(keepLocationWhenRecreate !== undefined, "Must have a keepLocationWhenRecreate value: var keepLocationWhenRecreate=true or false");

var sa = db.getMongo().getDB("sa");
var instruction = sa.instruction.findOne({_id:id});
assert(instruction, "The instruction is absent and must be created first.");
assert(instruction.fileSet, "The instruction has not fileSet.");
assert(instruction.label, "The instruction has no label.");

sa.stagingfile.remove({fileSet:instruction.fileSet});
assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not remove old instruction.");

db.master.files.find({'metadata.label':instruction.label}, {'metadata.content':0}).forEach(function (d) {
    var document = {
        na:na,
        access:d.access,
        contentType:d.contentType,
        md5:d.md5,
        length:d.length,
        pid:d.metadata.pid,
        seq:d.metadata.seq,
        objid:d.metadata.objid,
        fileSet:d.metadata.fileSet,
        version:NumberLong(0),
        _class:'org.objectrepository.instruction.StagingfileType'
    };

    if (instruction.access == document.access) delete document.access;
    if (instruction.contentType == document.contentType) delete document.contentType;
    if (instruction.objid == document.objid) delete document.objid;
    if (keepLocationWhenRecreate) document.location = merge(d.metadata.fileSet, d.metadata.l) + '/' + d.filename;
    if (d.metadata.lid) document.lid = d.metadata.lid;

    sa.stagingfile.save(document);
});


/**
 * merge
 *
 * Combine the fileSet and location element
 * Just like the ingest, the last folder of the fileSet and first folder of the location are the same.
 * We merge this here
 *
 * @param fileSet
 * @param l location
 */
var f = function merge(fileSet, l) {
    if (l) {
        var i = fileSet.lastIndexOf('/');
        var last = fileSet.substring(i);
        i = l.indexOf('/', 1);
        var first = l.substring(0, i);
        if (last == first) return fileSet + l.substring(i);
    }
    return fileSet;
}