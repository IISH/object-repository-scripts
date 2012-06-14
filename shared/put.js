/**
 * put.js
 *
 * Usage: mongo [database] --quiet --eval "var ns='[namespace]';var md5='[md5 as string]';length=[length];pid='[pid']"
 *
 * Purpose:
 * - prevent unnecessary file PUTs when the file's md5 and length are identical to a GridFS file.
 * - update metadata.pid during PID replacements
 * - removed documents when new filecontent is offered
 * - Upserts the 'master.metadata.cache' array to hold a cached version of our FSGrid storage.
 *
 * PUT actions will be the responsibility for mongofiles and cannot be performed by this script.
 **/

/**
 * Our model is the default GridFS with a namespace and its two buckets.
 * http://www.mongodb.org/display/DOCS/GridFS+Specification
 *
 * [ns].files:
 * {
 *      _id  : md5+hex(length)
 *      chunkSize : NumberLong
 *      length : NumberLong
 *      md5
 *      String filename
 *      uploadDate : ISODate
 *      contentType
 *      alias: null
 *
 *      metadata: {
 *          na // seems superfluous as the database has this name or_[na], but in an export we like to know where the document belongs.
 *          pid
 *          resolverBaseUrl
 *          access
 *          content
 *          label DBRef
 *          timesAccessed
 *          timesUpdated
 *          firstUploadDate : ISODate
 *          lastUploadDate : ISODate
 *          }
 * }
 *
 * [na].chunks:
 * {
 *      files_id: md5+hex(length)
 *      n
 *      data
 * }
 *
 * To conclude: the basis of our model is the default FSGrid with the [ns].files and [ns].chunks collections.
 * Key values: [ns].files._id (one) -- (many) [ns].chunks.files_id
 * metadata element is 'new' and not supported by the out of the box mongofiles utility.
 *
 * About the 'metadata' field:
 * In the [ns].files we will store the metadata element containing administrative and content metadata about
 * the file like resolution, access and number of updates, downloads.
 *
 * Indexes:
 * By default the _id and files_id fields are indexed.
 * In the [ns].files collection we will use the additional compound index as key: md5 plus length.
 * That is to say, we accept the unlikely situation where there may be different files stored
 * that have identical md5 hashes and so we fall back on a file length combination.
 **/

/**
 * Database and collection division.
 *
 * For each content provider we have a database: or_[na] where na is the number of the provider.
 *
 * At the moment collections per database are divided into:
 * master ( thus our buckets are the two GridFS collection master.files and master.chunks )
 * derivative levels 1 to 3
 *
 * Hence the database collections can look like:
 * > use or_[na]. Like use or_12345
 * > show collections
 *  level1.chunks
 *  level1.files
 *  level2.chunks
 *  level2.files
 *  level3.chunks
 *  level3.files
 *  master.chunks
 *  master.files
 *
 *  the master.files document is authoritative when it comes to 'access' settings: it is a String type.
 *  The similar setting in the derivative documents should be regarded as a DBRef to the master.
 **/

/**
 * Ingest procedure
 * Any file with a unique compound key is uploaded in the bucket.
 * Then this scripts is run to update the metadata.
 /**

 /**
 * updateCollections
 *
 * Systemic change of master and all derivatives by replacing the old metadata.pid with a new metadata.pid.
 * This method should be called when an identical master is offered with a new metadata.pid.
 *
 * This method cannot possibly be trickered by a derivative update.
 *
 * @param oldPid
 */

function updateCollections(oldPid) {

    print('Systemic identifier shift from ' + oldPid + ' to ' + pid);
    if (ns != 'master') {
        throw "Only an action intended for a master.files collection is allowed to reset all pids.";
    }
    var collectionNames = db.getCollectionNames();
    var length = collectionNames.length;
    var now = new Date();
    for (var i = 0; i < length; i++) {
        var collectionName = collectionNames[i];
        if (collectionName.lastIndexOf(".files") != -1) {
            print('updateCollections ' + collectionName + '.' + oldPid + ' to ' + pid);
            db.getCollection(collectionName).update({'metadata.pid':oldPid}, {
                $set:{
                    'metadata.pid':pid,
                    'metadata.lastUploadDate':now
                },
                $inc:{'metadata.timesUpdated':1}
            }, false, false);
        }
    }
}

/**
 * removeDocuments
 *
 * Remove the document and all other documents associated with the pid value
 */
function removeDocuments(master) {

    if (ns != 'master') {
        throw "Only an action intended for a master.files collection is allowed to remove all pids.";
    }

    var collectionNames = db.getCollectionNames();
    var length = collectionNames.length;
    for (var i = 0; i < length; i++) {
        var collectionName = collectionNames[i];
        var index = collectionName.lastIndexOf(".files");
        if (index != -1) {
            var namespace = collectionName.substring(0, index);
            var collection = db.getCollection(namespace + '.files');
            var document = (ns == namespace) ? master : collection.findOne({'metadata.pid':pid});
            if (document) {
                var files_id = document._id;
                print("Removing from " + namespace + '.' + pid);
                collection.remove({_id:files_id});
                db.getCollection(namespace + '.chunks').remove({files_id:files_id});
            }
        }
    }
}

/**
 * setMetadata
 *
 * When we save a new master file, we will set initial m.
 * For an update, we will update accordingly.
 *
 * For derivatives, we just copy parts of it into the metadata element FROM the master.
 */
function metadata(document) {

    var now = new Date();
    var m = document.metadata;
    m.bucket = ns;
    m.na = na;
    m.fileSet = fileSet;
    m.pid = pid;
    if ( lid ) m.lid = lid;
    m.access = access;
    m.label = label;
    m.resolverBaseUrl = resolverBaseUrl;
    m.timesUpdated = ( m.timesUpdated == undefined ) ? 0 : m.timesUpdated + 1;
    m.firstUploadDate = ( m.firstUploadDate == undefined ) ? now : m.firstUploadDate;
    m.lastUploadDate = now;
    m.timesAccessed = ( m.timesAccessed == undefined ) ? 0 : m.timesAccessed;
    if (content) m.content = content;

    files.save(document);
    print('Update metadata ' + files.getName() + ' ' + document.metadata.pid);
    printjson(document);
}

/**
 * cache
 *
 * Copy all metadata elements of non-master related files into the master.files array
 *
 * @param oldPid
 */
function cache() {

    print("caching");

    var cache = [];
    var collectionNames = db.getCollectionNames();
    var length = collectionNames.length;
    for (var i = 0; i < length; i++) {
        var collectionName = collectionNames[i];
        if (collectionName.lastIndexOf(".files") != -1) {
            var bucket = db.getCollection(collectionName).findOne({'metadata.pid':pid});
            if (bucket) {
                cache.push(
                    bucket
                )
            }
        }
    }
    db.getCollection('master.files').update( { 'metadata.pid': pid }, {$set:{'metadata.cache':cache}}, true, false );
}

var files = db.getCollection(ns + '.files');
var query = {$or:[
    {md5:md5, length:length, 'metadata.pid':pid},
    {'metadata.pid':pid}
]};
var list = files.find(query);

switch (list.count()) {
    case 0:
        // CASE 1: Pid replacement
        // Persisted is document    A {md5: a, 'metadata.pid': a}
        // We offered document      A (md5: a, 'metadata.pid': b)
        // Pid b is now to be used to identify A
        // We have a systemic change of identifiers.
        print("Case 1");
        var documentA = files.findOne({md5:md5, length:length});
        updateCollections(documentA.metadata.pid);
        break;
    case 1:
        // CASE 2: new document with new Pid. Found by md5,length,pid match
        // Persisted is     document A {md5: a, 'metadata.pid': a}
        // We offered       document A (md5: a, 'metadata.pid': a)
        // Only metadata will be changed:
        var isCase2 = list[0].md5 == md5 && list[0].length == length && list[0].metadata.pid == pid;
        if (isCase2) {
            print("Case 2");
            metadata(list[0]);
            break;
        }

        // CASE 3: Pid replacement and document removal.
        // Persisted is     document A {md5: a, 'metadata.pid': a}
        // Persisted is     document B {md5: b, 'metadata.pid': b}
        // Offered          document A {md5: a, 'metadata.pid': b}
        // Document B is to be removed and its metadata will replace that of A
        print("Case 3");
        var documentA = files.findOne({md5:md5, length:length});
        var documentB = list[0];
        assert(documentA, "Expected to find a document with a md5, length match.");
        removeDocuments(documentB);
        var dropPid = documentA.metadata.pid;
        documentA.metadata = documentB.metadata;
        metadata(documentA);
        updateCollections(dropPid);

        break;
    case 2:
        // CASE 4: Pid replacement and document removal
        // Persisted was     document A {md5: a, 'metadata.pid': a}
        // Persisted is      document B {md5: b, 'metadata.pid': a}
        // Result: two documents with the same pid a
        // We will remove the document A and move its metadata into the new document B.
        print("Case 4");
        var match = list[0].md5 == md5 && list[0].length == length;
        var documentA = ( match ) ? list[1] : list[0];
        var documentB = ( match ) ? list[0] : list[1];
        removeDocuments(documentA);
        documentB.metadata = documentA.metadata;
        metadata(documentB);
        break;
    default:
        print("Query resulted in too many documents.");
        printjson(query);
        throw "We found more than two documents !";
}

cache()
