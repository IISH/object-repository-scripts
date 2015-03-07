/**
 shardkey.2a.js

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

 A final check is to see if the shardkey is unique and not used by other clients by:
 - inserting the name_bucket_shardkey in a capped collection ( db.createCollection( 'key', { capped: true, size: 4096 } )
 - and when no duplicate error is thrown the bucket.files collection is queried for the shard key


 **/

load(lib_dir + 'randomseed.js');
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(db_shard, 'Must have the db_shard: var db_shard=\'host:port\' that stores the available shards.');
assert(file_size, 'Must have the file_size: var file_size = 12345');
var _test = (db.getName() == 'test');


var HOST_DB_NAME = 'shard';
var HOST_DB_CANDIDATE = 'candidate';
var HOST_DB_KEYS = 'key'; // a capped collection
var HOST_DB_SEQUENCE = 'sequence'; // a collection with a single document for incremental values.
var GiB = 1073741824;

// CANDIDATE_LIMIT: the number of candidate shards to retrieve
var CANDIDATE_LIMIT = 20;

// CANDIDATE_EXPIRED: the moment the candidate should and should not be included in the find.
var CANDIDATE_EXPIRED = 70000; // 70 seconds

// RETRY_SHARDKEY: the number of attempts to find a shardkey by incrementing the rejected shardkey by one.
var RETRY_SHARDKEY = 10;


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
 * getLastShardKey
 *
 * Returns the files_id key with the highest value. If not found, use the host default minkey.
 *
 * @param candidate The candidate host
 */
function getLastShardKey(candidate) {
    var remote_host = connect(candidate._id + '/' + db.getName());
    var chunks = remote_host[bucket + '.chunks'].find({n: 0}, {files_id: 1}).sort({files_id: -1}).limit(1);
    return (chunks.length()) ? chunks[0].files_id : candidate.minkey;
}


/**
 * compoundKey
 *
 * Prefix a namespace to the shardKey.
 */
function compoundKey(shardKey) {
    return db.getName() + '.' + bucket + '.' + shardKey;
}


/**
 * availableShardKey
 *
 * Determine if the suggested key is available.
 * Should the key be in use, we increment the key by one and retry for RETRY_SHARDKEY times.
 */
function availableShardKey(candidate_shardkey) {
    var l = candidate_shardkey + RETRY_SHARDKEY;
    for (var shardkey = candidate_shardkey; shardkey < l; shardkey++) {
        var unique_id = compoundKey(shardkey);
        db_shard_connection[HOST_DB_KEYS].insert({_id: unique_id});
        var writeResult = db_shard_connection.runCommand({getlasterror: 1});
        if (writeResult.err == null && db[bucket + '.files'].findOne({_id: shardkey}, {_id: 1}) == null)
            return shardkey;
    }
    throw 'Error: Unable to provide an unique shardkey for the suggested ' + candidate_shardkey;
}


/**
 * printShardKey
 *
 * Get the highest valued shard key from the bucket.
 * Once a candidate shard and key is found, we try to write the shard key into the capped keys collection to avoid a
 * race condition with other shardkey.js clients that like to write with the same key.
 */
function printShardKey() {
    var candidate = getCandidate();
    var candidate_shardkey = (candidate.version == 1) ? candidate.minkey + Math.floor(Math.random() * (candidate.maxkey - candidate.minkey - RETRY_SHARDKEY)) // Legacy
        : getLastShardKey(candidate) + 1;

    var shardKey = availableShardKey(candidate_shardkey);
    if (shardKey >= candidate.minkey && shardKey <= candidate.maxkey)
        return shardKey;

    throw 'Error: The shardkey ' + shardKey + ' cannot have a value that is lower than the minkey (' + candidate.minkey + ') or higher than the maxkey (' + candidate.maxkey + ') of the intended shard ' + candidate.setName;
}


if (_test)
    print('Ready for unit testing.');
else
    print(printShardKey());