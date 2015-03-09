/**
 shardkey.2a.js

 Usage: shardkey.2a.js --eval "var bucket='bucket name'; var db_shard = 'primary with the shard.candidate collection:port'; var file_size=NumberLong('file size in bytes'); var lib_dir='/path/to/libraries/'"

 Returns a shardkey for a shard.

 Which shardkey depends on one of the members of the replica set. The member with the highest rs.config.members[n].priority
 must always be in the state of 1 ( master) to become a host for the file by shardkey.
 Each member has a bash script that runs every minute. They update a document which contains:
 {
     _id: the member's host:port,
     active: true if this node is allowed to receive storage requests,
     setName: the replica set name,
     minkey: minkey is the shard's lower key value,
     version: 2 for producing incremental keys; or 1 for random ( legacy ),
     used:storage used on the host's filesystem,
     avail: storage free on the fs,
     usable: storage usable by the fs.
     date: the heartbeat date. The document is stale if CANDIDATE_EXPIRED
 }

 To determine a shard key a shard candidate is plucked from  a list.
 The list may only contain shard candidates when:
 - active = true
 - the file size in GiB is a value lower than the candidate's 'usable' value.

 A candidate is then picked from the list sequentially to lessen the change other clients retrieve a shardkey for the same host.

 The shard's host is contacted to determine the chunk with the highest files_id in use and this value is either
 incremented by one ( when version is > 1 ) or chosen ad random for version 1.
 If no chunks are found, the minkey value is used and incremented by one.

 A final check is to see if the shardkey is unique and not used by other clients by
 inserting a reserved document: the db[bucket.files].insert({_id:shardkey, reserved:true})
 There should be no unique constraint error, unless the shardkey is already in use.


 **/

load(lib_dir + 'randomseed.js');
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(db_shard, 'Must have the db_shard: var db_shard=\'host:port\' that stores the available shards.');
assert(file_size, 'Must have the file_size: var file_size = 12345');
var _test = (db.getName() == 'test');
var _log = [];

var HOST_DB_NAME = 'shard';
var HOST_DB_CANDIDATE = 'candidate';
var HOST_DB_SEQUENCE = 'sequence'; // a collection with a single document for incremental values.
var GiB = 1073741824;

// CANDIDATE_LIMIT: the number of candidate shards to retrieve
var CANDIDATE_LIMIT = 20;

// CANDIDATE_EXPIRED: the moment the candidate should and should not be included in the find.
var CANDIDATE_EXPIRED = 70000; // 70 seconds

// RETRY_shardkey: the number of attempts to find a shardkey by incrementing the rejected shardkey by one.
var RETRY_shardkey = 10;


Math.seedrandom(ObjectId().valueOf());


// Connect to the shard database that has the candidates.
var db_shard_connection = connect(db_shard + '/' + HOST_DB_NAME);


/**
 * listCandidates
 *
 * Retrieve the candidates with the highest available storage that have enough room for the file.
 */
function listCandidates() {

    var expired = new Date(new Date().getTime() - CANDIDATE_EXPIRED);
    var file_size_GiB = Math.ceil(file_size / GiB);
    return db_shard_connection[HOST_DB_CANDIDATE].find({active: true, usable: {$gte: file_size_GiB}, date: {$gt: expired}})
        .sort({usable: -1}).limit(CANDIDATE_LIMIT);
}


/**
 * pick
 *
 * Increment sequence.{_id:'counter', seq}.seq by one.
 * Then use the value to get an index.
 *
 */
function pick(size) {

    var counter = db_shard_connection[HOST_DB_SEQUENCE].findAndModify(
        {
            query: { _id: db.getName() + '.' + bucket },
            upsert: true,
            update: { $inc: { seq: 1 } },
            new: true
        }
    );

    return counter.seq % size;
}


/**
 * getCandidate
 *
 * Pick a shard from a list.
 */
function getCandidate() {
    var candidates = listCandidates(file_size);
    assert(candidates.length(), 'No suitable candidates found. The replica sets may all be unavailable. Or the file may be larger than the usable storage and cannot be stored.');
    var candidate = candidates[pick(candidates.length())];
    assert(candidate.version, 'The candidate shard has no version');
    assert(candidate.minkey, 'The candidate shard does not have a minkey');
    assert(candidate.maxkey, 'The candidate shard has no maxkey');
    return candidate;
}


/**
 * getLastShardkey
 *
 * Returns the _id key with the highest value covered by the shard. If not found, use the host default minkey.
 *
 * @param candidate The candidate host
 */
function getLastShardkey(candidate) {
    var files = db[bucket + '.files'].find({_id: {$gte: candidate.minkey, $lte: candidate.maxkey}}, {_id: 1}).sort({_id: -1}).limit(1);
    return (files.length()) ? files[0]._id : candidate.minkey;
}


/**
 * reserveShardkey
 *
 * Determine if the suggested key is available.
 * Should the key be in use the writeError will indicate a E11000 duplicate key error index.
 * If so, we increment the key by one and retry for RETRY_shardkey number of times.
 */
function reserveShardkey(candidate_shardkey) {
    var l = candidate_shardkey + RETRY_shardkey;
    for (var shardkey = candidate_shardkey; shardkey < l; shardkey++) {
        db[bucket + '.files'].insert({_id: shardkey, metadata: {pid: shardkey}});
        var writeResult = db.runCommand({getlasterror: 1});
        if (writeResult.err) {
            _log.push({error: {shardkey: shardkey, writeResult: writeResult}});
        }
        else
            return shardkey;
    }
    printjson(_log);
    throw 'Unable to reserve an unique shardkey for the suggested ' + candidate_shardkey;
}


/**
 * printShardkey
 *
 * Get the highest valued shard key from the bucket.
 * Once a candidate shard and key is found, we try to write the shard key into the capped keys collection to avoid a
 * race condition with other shardkey.js clients that like to write with the same key.
 */
function printShardkey() {
    var candidate = getCandidate();
    _log.push({candidate: candidate});
    var candidate_shardkey = (candidate.version == 1) ? candidate.minkey + Math.floor(Math.random() * (candidate.maxkey - candidate.minkey - RETRY_shardkey)) // Legacy
        : getLastShardkey(candidate) + 1;

    var shardkey = reserveShardkey(candidate_shardkey);
    assert(shardkey >= candidate.minkey && shardkey <= candidate.maxkey);
    return shardkey;
}


if (_test)
    print('Ready for unit testing.');
else
    print(printShardkey());