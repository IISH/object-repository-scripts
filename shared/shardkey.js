/**
 shardkey.js

 Returns an shardkey for a shard with a preference for the lowest data size.
 The shard must have an online\live primary, or else the returned value is zero.

 By doing so it creates a collection with reserved shard candidates stored in the candidate collection.
 **/

load(dependencies);
assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
var shards = db.candidate.findOne({_id:'shards'});
assert(shards, 'Must have a list of shard min keys defined');
delete shards._id;

var slice = 1.5; // List cannot contain any more than a round [total shard number] / [slice]
var total = 10; // Total number of candidate keys per shard for this bucket. Number of keys produced will be [total shard number] / [slice] * total


/**
 * getShardCandidate
 *
 * Returns the next shard from the candidate collection.
 * If we are out of candidates, the collection will be refilled using the stats command.
 *
 * The stats command may take a second or minutes, depending on the state of the nodes. This will inevitably
 * lead to other clients calling this method that invoke this script. To prevent this the shards in the shards list
 * are added to the candidate collection.
 *
 * @return {*}
 */
function getShardCandidate() {

    Math.seedrandom(ObjectId().valueOf());

    var doc = db.candidate.runCommand("findAndModify", {query:{b:bucket}, sort:{ _id:1 }, remove:true });
    if (doc && doc.value && doc.value.s) {
        return doc.value.s;
    } else {
        for (var shardId in shards) {
            if (shards.hasOwnProperty(shardId)) {
                db.candidate.save({s:shardId, b:bucket});
            }
        }

        var stats = (db.getName() == 'test') ? {shards:{}} : db.getCollection(bucket + '.chunks').stats();
        var limit = Object.keySet(shards).length / slice;
        var list = [];
        var l = {};
        for (var c = 0; c < total; c++) {
            for (shardId in shards) {
                if (shards.hasOwnProperty(shardId)) {
                    var shard = stats.shards[shardId];
                    var size = (shard) ? Math.round(Math.sqrt(shard.size)) : 0;
                    if (Object.keySet(l).length < limit) {
                        l[shardId] = size;
                    } else {
                        for (var item in l) {
                            if (l.hasOwnProperty(item)) {
                                if (l[item] > size) {
                                    l[shardId] = size;
                                    delete l[item];
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            for (shardId in l) {
                if (l.hasOwnProperty(shardId)) {
                    list.push(shardId);
                }
            }
        }

        var candidate = list.pop();// This is the one we return with this request. So we save all minus this one.

        list.forEach(function (shardId) {
            db.candidate.save({s:shardId, b:bucket});
        });

        return candidate;
    }
}

var new_id = 0;
for (var i = 0; i < total; i++) { // We try the [total] amount of times.
    var candidate = getShardCandidate();
    assert(candidate, 'No candidate shard found');
    var shard = shards[candidate];
    assert(shard, 'ShardId not found: ' + candidate.s);
    assert(shard.minKey, 'Missing minKey');
    assert(shard.interval, 'Missing interval');
    assert(shard.s, 'Replica secondary host definition missing');

    // Is the shard available ?
    var expired = new Date(new Date().getTime() - 3600000); // 1 hour
    if (db.candidate.findOne({_id:candidate + "_" + bucket, d:{$gt:expired}})) continue;

    var host = null; // Verify the shard candidate has an active (replicating) secondary... otherwise choose another.
    try {
        host = (db.getName() == 'test') ? {serverStatus:function () {
            return {repl:{ismaster:false, secondary:true}}
        }} : connect(shard.s + '/test');
    } catch (e) {
        continue;
    }

    var repl = host.serverStatus().repl;
    assert(repl, 'Host is not a replicaset: ' + shard);
    if (repl.secondary && !repl.ismaster) {
        do {
            new_id = shard.minKey + Math.round(Math.random() * shard.interval);
        } while (new_id == 0 || db.getCollection(bucket + '.files').findOne({_id:new_id}, {_id:1}));
        break;
    }
}

print(new_id);