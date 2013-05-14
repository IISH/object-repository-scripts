/**
 recreate.js

 Take all metadata from a single file into a instruction
 **/

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
assert(id, "Must have a id: var id='?'");

var sa = db.getMongo().getDB("sa");
var instruction = sa.instruction.findOne(ObjectId(id));
assert(instruction, "The instruction is absent and must be created first.");
assert(instruction.fileSet, "The instruction has not fileSet.");
assert(instruction.label, "The instruction has no label.");