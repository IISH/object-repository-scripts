/**
 * candidate_history.js
 *
 * Copy all candidate documents into the history collection.
 * Create a report for the last -from days.
 *
 * @from ( default 7 )
 * The days backwards in time to aggregate the report with. For example from=10 will cover
 * everything from the last ten days counting from today.
 **/


assert(db.getName() == 'shard', 'Expect the database name to be "shard"');
assert(Number(from));


var HOST_DB_CANDIDATE = 'candidate';
var HOST_DB_HISTORY = 'history';
var C = ',';
var DAY = 86400000;

/**
 * getId
 *
 * Build and return a string from a date in the format YYYY-MM-DD
 */
function formatDate(date) {

    function pad(n) {
        return n < 10 ? '0' + n : n
    }

    return date.getUTCFullYear() + '-' + pad(date.getUTCMonth() + 1) + '-' + pad(date.getUTCDate());
}


/**
 * saveCandidateHistory
 *
 * Aggregate the candidates into one and save it with today's date.
 */
function saveCandidateHistory() {
    var date = new Date();
    var history = {_id: formatDate(date), date: date, avail: 0, used: 0, usable: 0};
    db[HOST_DB_CANDIDATE].find().forEach(function (candidate) {
        history.avail += candidate.avail;
        history.used += candidate.used;
        history.usable += candidate.usable;
        db[HOST_DB_HISTORY].save(history);
    });
}


function quote(value) {
    return '"' + value + '"';
}


/**
 * report
 *
 * Printout a CSV list
 */
function report() {
    var _from = new Date(new Date().getMilliseconds() + from * DAY);
    var candidates = db[HOST_DB_HISTORY].find({date: {$gte: _from}}).sort({date: 1});
    var usable = 0;

    print('"DATE", "REPLSET","AVAIL", "USED", "USABLE"');
    candidates.forEach(function (candidate) {
        usable += candidate.usable;
        print(quote(formatDate(candidate.date)) + C + quote(candidate.avail) + C + quote(candidate.used) + C + quote(candidate.usable));
    });

    return usable;
}

saveCandidateHistory();
report();

