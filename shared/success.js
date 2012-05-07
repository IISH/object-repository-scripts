/**
 * success.js
 *
 * Usage: mongo [database=sa] --quiet --eval "var fileSet, id and task name"
 **/

assert(id, "Must have an identifier 'id'");
assert(name, "Must have a task name 'name'");
assert(fileSet, "Must have a fileSet 'fileSet");

// Update the instruction workflow status
var query = {fileSet:fileSet, 'workflow.name': name};
var update = {$inc:{'workflow.$.processed':1}};
db.getCollection('instruction').update(query, update, false, false);

// Update the stagingfile task and workflow status
query = {_id:new ObjectId(id), 'workflow.name': name};
update = {$set:{'task.name':name,'task.statusCode':800, 'workflow.$.statusCode':800}};
db.getCollection('stagingfile').update(query, update, false, false);
