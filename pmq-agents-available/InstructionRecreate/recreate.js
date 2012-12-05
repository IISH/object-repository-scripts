/**
 recreate.js

 Take all metadata from the master files into a instruction
 **/

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(na, "Need a naming authority");
assert(fileSet, "Must have a fileSet: var fileSet='?'");

var sa = db.getMongo().getDB("sa");
var instruction = sa.instruction.findOne({fileSet:fileSet});
assert(instruction, "The instruction is absent and must be created first.");

db.master.files.find({'metadata.fileSet':fileSet}, {'metadata.content':0}).forEach(function (d) {
printjson(d);
    var document = {
        na:na,
        access:d.access,
        contentType:d.contentType,
        md5:d.md5,
        length:d.length,
        pid:d.metadata.pid,
        fileSet:fileSet,
        version : NumberLong(0),
        _class : 'org.objectrepository.instruction.StagingfileType'
    };

    if ( instruction.access == document.access ) delete document.access;
    if ( instruction.contentType == document.contentType ) delete document.contentType;
    if (d.metadata.lid) document.lid = d.metadata.lid;

    sa.stagingfile.save(document);
});