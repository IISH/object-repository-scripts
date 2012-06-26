// Added element for pid url per collection type.

/*
 var masterCollection = db.getCollection('master.files');
 masterCollection.update( {}, {$set:{'metadata.pidType':'or'}}, true, true);
 masterCollection.update( {}, {$unset:{'metadata.pidtype':1}}, true, true);

 var pids = [];
 masterCollection.find({}, {'metadata.pid':1}).forEach(function (master) {
 pids.push(master.metadata.pid);
 });

 var collectionNames = db.getCollectionNames();
 var length = collectionNames.length;

 for (var p = 0; p < pids.length; p++) {
 var pid = pids[p];
 var cache = [];
 var master = null;
 for (var i = 0; i < length; i++) {
 var collectionName = collectionNames[i];
 if (collectionName.lastIndexOf(".files") != -1) {
 var collection = db.getCollection(collectionName);
 var bucket = collection.findOne({'metadata.pid':pid});

 if (bucket) {
 if (collectionName == 'master.files') {
 master = bucket;
 delete bucket.metadata.cache;
 }
 bucket.metadata.pidUrl = 'http://hdl.handle.net/' + pid + '?locatt=view:' + bucket.metadata.bucket;
 cache.push(
 bucket
 )
 }
 }
 }
 masterCollection.update({_id:master._id}, {$set:{'metadata.cache':cache}}, true, true);
 }
 */