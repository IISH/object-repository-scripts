/**
 recreate.js

 Take all metadata from the master files into a instruction
 **/

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(fileSet, "Must have a fileSet: var fileSet='?'");

var sa = db.getMongo().getDB("sa");
var instruction = sa.instruction.findOne({fileSet:fileSet});
assert(instruction, "The instruction is absent and must be created first.");

db.master.files.find({'metadata.fileSet':fileSet}, {'metadata.content':0}).forEach(function (d) {
    var document = {
        access:d.access,
        contentType:d.contentType,
        md5:d.md5,
        length:d.length,
        pid:d.pid,
        fileSet:fileSet
    };
    if (d.lid) document.lid = d.lid;
    sa.stagingfile.save(document);
});