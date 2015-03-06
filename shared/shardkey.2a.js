/**
 shardkey.js

 Returns a shardkey for a shard with a preference for the highest available storage.

 Each intended primary is a candidate.
 The primary has a bash script that runs every minute. They update a document which contains:
 {
     _id: the primary's hostname:port,
     active: true if this primary ay receive data,
     setName: the replica set name,
     minkey: minkey,
     used:storage used,
     avail: storage available,
     usable: storage usable,
     date: the heartbeat date
 }

 To determine a shard key a shard candidate is plucked from  a list.
 The list may only contain shard candidates when:
 - active = true
 - the file size in GiB is a value lower than the candidate's 'usable' value.

 A candidate is then taken from the list ad random.
 The shard's host is contacted to determine the highest files_id in use and this value is incremented by one.

 A final check is to see if the shardkey is unique and not used by other clients.

 **/

load(dependencies);
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(db_shard, 'Must have the db_shard: var db_shard=\'host:port\' that stores the available shards.');
assert(file_size, 'Must have the file_size: var file_size = 12345');
assert(file_size > 0, 'A file cannot be zero in length.');
var debug = (debug !== undefined);


var HOST_DB_NAME = 'shard';
var HOST_DB_CANDIDATE = 'candidate';
var HOST_DB_KEYS = 'key'; // a capped collection
var GiB = 1073741824;

// CANDIDATE_LIMIT: the number of candidate shards to retrieve
var CANDIDATE_LIMIT = 10;

// CANDIDATE_EXPIRED: the moment the candidate should and should not be included in the find.
var CANDIDATE_EXPIRED = 90000; // 90 seconds


Math.seedrandom(ObjectId().valueOf());


/**
 * listCandidates
 *
 * Retrieve the candidates with the highest available storage that have enough room for the file.
 */
function listCandidates() {

    var expired = new Date(new Date().getTime() - CANDIDATE_EXPIRED);
    var file_size_GiB = Math.ceil(file_size / GiB);
    var db_shard_connection = connect(db_shard + '/' + HOST_DB_NAME);
    return db_shard_connection[HOST_DB_CANDIDATE].find({active: true, usable: {$gt: file_size_GiB}, date: {$gt: expired}})
        .sort({usable: -1}).limit(CANDIDATE_LIMIT);
}

/**
 * getCandidate
 *
 * Pick a shard from a list.
 */
function getCandidate() {
    var candidates = listCandidates(file_size);
    var length = candidates.length();
    assert(length, 'No suitable candidates found. The replica sets may all be unavailable. Or the file may be larger than the usable storage and cannot be stored.');
    if (debug)
        printjson(candidates);
    return candidates[Math.floor(Math.random() * length)];
}

/**
 * getShardKey
 *
 * Get the highest valued shard key from the bucket.
 * Once a candidate shard and key is found, we try to write the shard key into the capped keys collection to avoid a
 * race condition with other shardkey.js clients that like to write with the same key.
 */
function getShardKey() {
    var candidate = getCandidate();
    var remote_host = connect(candidate.host + '/' + db.getName());
    var chunks = remote_host[bucket + '.chunks'].find({n: 0}, {files_id: 1}).sort({files_id: -1}).limit(1);
    var shardKey = (chunks.length()) ? chunks[0].files_id : candidate.minkey;

    // We try this for ten times just in case we have a orphan metadata record in the bucket.files collection.
    var db_shard_connection = connect(db_shard + '/' + HOST_DB_NAME);
    for (var i = 0; i < 10; i++) {
        shardKey++;
        var unique_id = db.getName() + '_' + bucket + '_' + shardKey;
        db_shard_connection[HOST_DB_KEYS].insert({_id: unique_id});
        var writeResult = db.runCommand({getlasterror: 1});
        if (writeResult.err == null && db[bucket + '.files'].findOne({_id: shardKey}, {_id: 1}) == null)
            return shardKey;
    }

    throw 'Unable to create a unique key or to verify it is unique: ' + shardKey;
}

print(getShardKey());