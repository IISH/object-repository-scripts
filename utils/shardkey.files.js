/**
 * Produce an evenly distributed sharded key range
 */

assert(db.getName() != 'test', "The database is the test database. Startup specifying a production database: 'mongo host/database'");
var filesFrom = db.getCollection("m.files");
var filesTo = db.getCollection("master.files");

filesFrom.update({}, {$unset:{'metadata.cache':1}}, true, true);
var expect = filesFrom.count();
var count = 0;
var range = 1431655765; // 2^32 / 3
var shard = {or0:{size:0, count:0}, or1:{size:0, count:0}, or2:{size:0, count:0}};
filesFrom.find().forEach(function (d) {

    var new_id = Math.floor(Math.random() * range);
    var s = null;
    if (shard.or0.size <= shard.or1.size && shard.or0.size <= shard.or2.size) {
        shard.or0.size += d.length / 1048576;
        new_id += -2147483648;
        shard.or0.count++;
    } else if (shard.or1.size <= shard.or0.size && shard.or1.size <= shard.or2.size) {
        shard.or1.size += d.length / 1048576;
        new_id += -715827883;
        shard.or1.count++;
    } else {
        shard.or2.size += d.length / 1048576;
        new_id += 715827882;
        shard.or2.count++;
    }

    d.metadata.old_id = d._id;
    d._id = new_id;
    print("{new_id:" + d._id + " , old_id:" + d.metadata.old_id);
    count++;
    filesTo.save(d);
});

print("Found: " + count);
print("Shard count: {shard.or0.count:" + shard.or0.count + ",shard.or1.count:" + shard.or1.count + ",shard.or2.count:" + shard.or2.count + ",total:" + (shard.or0.count + shard.or1.count + shard.or2.count));
print("Shard size: {shard.or0.size:" + shard.or0.size + ",shard.or1.size:" + shard.or1.size + ",shard.or2.size:" + shard.or2.size + ",total:" + (shard.or0.size + shard.or1.size + shard.or2.size));
print("Expect: " + expect);
print("Found: " + filesTo.count());

db.master.files.ensureIndex({'metadata.old_id':1},{unique:true});
printjson(db.m.files.find({},{_id:1,'metadata.pid':1}).forEach(function(d){var c=db.master.files.count({'metadata.old_id':d._id});if ( c != 1 ) { print("Odd count " + c + " " + d._id + " " + d.metadata.pid) }; }));
