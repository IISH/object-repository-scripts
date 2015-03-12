/**
 * snapshot.js
 *
 * Copy all candidate documents into the history collection
 **/


assert(db.getName() == 'shard', 'Expect the database name to be "shard"');


var HOST_DB_CANDIDATE = 'candidate';
var HOST_DB_HISTORY = 'history';


var date = new Date();
db[HOST_DB_CANDIDATE].find().forEach(function (candidate) {
    delete candidate._id;
    candidate.date = date;
    db[HOST_DB_HISTORY].save(candidate);
});