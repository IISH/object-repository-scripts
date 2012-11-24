/**
 shardkey.js

 Returns an shardkey for a shard with a preference for the lowest data size.
 The shard must have an online\live primary, or else the returned value is zero.

 By doing so it creates a collection with reserved shard candidates stored in the candidate collection.
 **/

assert(bucket, 'Must have a bucket namespace defined: var bucket="?"');
assert(shards, 'Must have a list of shard min keys defined: var shards="shards"');

var slice = 1.5; // List cannot contain any more than [total shard number] / [slice]
var total = 10; // Total number of candidate keys per shard for this bucket. Number of keys produced will be [total shard number] / [slice] * total
var interval = 1431655765; // interval of a shard.
var shardkey = 0;

function getShardCandidate() {

    var doc = db.candidate.runCommand("findAndModify", {query:{b:bucket}, sort:{ _id:1 }, remove:true });
    if (doc && doc.value && doc.value.s) {
        return doc.value.s;
    } else {
        var stats = (db.getName() == 'test') ? {shards:{}} : db.getCollection(bucket + '.chunks').stats();

        var limit = Object.keySet(shards).length / slice;
        var list = [];
        var l = {};
        for (var c = 0; c < total; c++) {
            for (var shardId in shards) {
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


for (var i = 0; i < total; i++) { // We try the [total] amount of times.
    var candidate = getShardCandidate();
    assert(candidate, 'No candidate shard found');
    var shard = shards[candidate];
    assert(shard, 'ShardId not found: ' + candidate.s);

    var removeDb = null;// Verify the shard candidate belongs to an active primary... otherwise choose another.
    try {
        removeDb = (db.getName() == 'test') ? {serverStatus:function () {
            return {repl:{ismaster:true, secondary:false}}
        }} : connect(shard.p + '/test');
    } catch (e) {
        continue;
    }

    var repl = removeDb.serverStatus().repl;
    assert(repl, 'Host is not a replicaset: ' + shard);
    if (repl.ismaster && !repl.secondary) {
        do {
            shardkey = shard.minKey + Math.round(Math.random() * interval);
        } while (db.getCollection(bucket + '.files').findOne({_id:shardkey}, {_id:shardkey}));
        break;
    }
}

print(shardkey);
