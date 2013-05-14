/**
 recreate.js

 Take all metadata from the master files into a instruction
 **/

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(na, "Need a naming authority");
assert(id, "Must have a id: var id='?'");

var sa = db.getMongo().getDB("sa");
var instruction = sa.instruction.findOne(ObjectId(id));
assert(instruction, "The instruction is absent and must be created first.");
assert(instruction.fileSet, "The instruction has not fileSet.");
assert(instruction.resubmitPid, "The instruction has no resubmitPid element.");

sa.stagingfile.remove({pid:instruction.resubmitPid});
assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not remove old instruction.");

db.master.files.find({'metadata.pid':instruction.resubmitPid}, {'metadata.content':0}).forEach(function (d) {
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
    document.location = d.metadata.l + '/' + d.filename;
    if (d.metadata.lid) document.lid = d.metadata.lid;

    sa.stagingfile.save(document);
});