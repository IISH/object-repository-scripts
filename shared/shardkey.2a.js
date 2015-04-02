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

// Math.random seed taken from seedrandom.js version 2.0.
// Author: David Bau 4/2/2011
//
// LICENSE (BSD):
//
// Copyright 2010 David Bau, all rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//   1. Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
//   2. Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//
//   3. Neither the name of this module nor the names of its contributors may
//      be used to endorse or promote products derived from this software
//      without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

/**
 * All code is in an anonymous closure to keep the global namespace clean.
 *
 * @param {number=} overflow
 * @param {number=} startdenom
 */
(function (pool, math, width, chunks, significance, overflow, startdenom) {
//
// seedrandom()
// This is the seedrandom function described above.
//
    math['seedrandom'] = function seedrandom(seed, use_entropy) {
        var key = [];
        var arc4;

        // Flatten the seed string or build one from local entropy if needed.
        seed = mixkey(flatten(
            use_entropy ? [seed, pool] :
                arguments.length ? seed :
                    [new Date().getTime(), pool, window], 3), key);

        // Use the seed to initialize an ARC4 generator.
        arc4 = new ARC4(key);

        // Mix the randomness into accumulated entropy.
        mixkey(arc4.S, pool);

        // Override Math.random

        // This function returns a random double in [0, 1) that contains
        // randomness in every bit of the mantissa of the IEEE 754 value.

        math['random'] = function random() {  // Closure to return a random double:
            var n = arc4.g(chunks);             // Start with a numerator n < 2 ^ 48
            var d = startdenom;                 //   and denominator d = 2 ^ 48.
            var x = 0;                          //   and no 'extra last byte'.
            while (n < significance) {          // Fill up all significant digits by
                n = (n + x) * width;              //   shifting numerator and
                d *= width;                       //   denominator and generating a
                x = arc4.g(1);                    //   new least-significant-byte.
            }
            while (n >= overflow) {             // To avoid rounding up, before adding
                n /= 2;                           //   last byte, shift everything
                d /= 2;                           //   right using integer math until
                x >>>= 1;                         //   we have exactly the desired bits.
            }
            return (n + x) / d;                 // Form the number within [0, 1).
        };

        // Return the seed that was used
        return seed;
    };

//
// ARC4
//
// An ARC4 implementation.  The constructor takes a key in the form of
// an array of at most (width) integers that should be 0 <= x < (width).
//
// The g(count) method returns a pseudorandom integer that concatenates
// the next (count) outputs from ARC4.  Its return value is a number x
// that is in the range 0 <= x < (width ^ count).
//
    /** @constructor */
    function ARC4(key) {
        var t, u, me = this, keylen = key.length;
        var i = 0, j = me.i = me.j = me.m = 0;
        me.S = [];
        me.c = [];

        // The empty key [] is treated as [0].
        if (!keylen) {
            key = [keylen++];
        }

        // Set up S using the standard key scheduling algorithm.
        while (i < width) {
            me.S[i] = i++;
        }
        for (i = 0; i < width; i++) {
            t = me.S[i];
            j = lowbits(j + t + key[i % keylen]);
            u = me.S[j];
            me.S[i] = u;
            me.S[j] = t;
        }

        // The "g" method returns the next (count) outputs as one number.
        me.g = function getnext(count) {
            var s = me.S;
            var i = lowbits(me.i + 1);
            var t = s[i];
            var j = lowbits(me.j + t);
            var u = s[j];
            s[i] = u;
            s[j] = t;
            var r = s[lowbits(t + u)];
            while (--count) {
                i = lowbits(i + 1);
                t = s[i];
                j = lowbits(j + t);
                u = s[j];
                s[i] = u;
                s[j] = t;
                r = r * width + s[lowbits(t + u)];
            }
            me.i = i;
            me.j = j;
            return r;
        };
        // For robust unpredictability discard an initial batch of values.
        // See http://www.rsa.com/rsalabs/node.asp?id=2009
        me.g(width);
    }

//
// flatten()
// Converts an object tree to nested arrays of strings.
//
    /** @param {Object=} result
     * @param {string=} prop
     * @param {string=} typ */
    function flatten(obj, depth, result, prop, typ) {
        result = [];
        typ = typeof(obj);
        if (depth && typ == 'object') {
            for (prop in obj) {
                if (obj.hasOwnProperty(prop)) {
                    if (prop.indexOf('S') < 5) {    // Avoid FF3 bug (local/sessionStorage)
                        try {
                            result.push(flatten(obj[prop], depth - 1));
                        } catch (e) {
                        }
                    }
                }
            }
        }
        return (result.length ? result : obj + (typ != 'string' ? '\0' : ''));
    }

//
// mixkey()
// Mixes a string seed into a key that is an array of integers, and
// returns a shortened string seed that is equivalent to the result key.
//
    /** @param {number=} smear
     * @param {number=} j */
    function mixkey(seed, key, smear, j) {
        seed += '';                         // Ensure the seed is a string
        smear = 0;
        for (j = 0; j < seed.length; j++) {
            key[lowbits(j)] =
                lowbits((smear ^= key[lowbits(j)] * 19) + seed.charCodeAt(j));
        }
        seed = '';
        for (j in key) {
            if (key.hasOwnProperty(j)) seed += String.fromCharCode(key[j]);
        }
        return seed;
    }

//
// lowbits()
// A quick "n mod width" for width a power of 2.
//
    function lowbits(n) {
        return n & (width - 1);
    }

//
// The following constants are related to IEEE 754 limits.
//
    startdenom = math.pow(width, chunks);
    significance = math.pow(2, significance);
    overflow = significance * 2;

//
// When seedrandom.js is loaded, we immediately mix a few bits
// from the built-in RNG into the entropy pool.  Because we do
// not want to intefere with determinstic PRNG state later,
// seedrandom will not call math.random on its own again after
// initialization.
//
    mixkey(math.random(), pool);

// End anonymous scope, and pass initial values.
})(
    [], // pool: entropy pool starts empty
    Math, // math: package containing random, pow, and seedrandom
    256, // width: each RC4 output is 0 <= x < 256
    6, // chunks: at least six RC4 outputs for each double
    52    // significance: there are 52 significant digits in a double
);



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