/**
 * put.js
 *
 * Usage: mongo [database] --quiet --eval "var ns='[namespace]';var md5='[md5 as string]';length=[length];pid='[pid']"
 *
 * Purpose:
 * - prevent unnecessary file PUTs when the file's md5 and length are identical to a GridFS file.
 * - update metadata.pid during PID replacements
 * - removed documents when new filecontent is offered
 *
 * PUT actions will be the responsibility for mongofiles and cannot be performed by this script.
 **/

/**
 * Our model is the default GridFS collection with a namespace and its two buckets: files and chunks.
 * http://www.mongodb.org/display/DOCS/GridFS+Specification
 *
 * [ns].files:
 * {
 *      _id  : integer 32 bit
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
 *      files_id: integer 32 bit
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
 * In the [ns].files collection we will use the metadata.pid as unique key.
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
 * setMetadata
 *
 * When we save a new file, we will set initial m.
 * For an update, we will update accordingly.
 *
 * For derivatives, we just copy parts of it into the metadata element FROM the master.
 */

// First a normalization. The md5 in the mongodb collection is always 32 characters in length
md5 = "00000000000000000000000000000000" + md5;
md5 = md5.substring(md5.length - 32);

function appendExtension(filename, contentType) {
    var i = contentType.indexOf('/');
    var extension = (i == -1) ? 'bin' : contentType.substring(i + 1);
    i = filename.lastIndexOf('.');
    var f = (i == -1) ? filename : filename.substring(0, i);
    return f + '.' + extension;
}

function metadata(document) {

    var now = new Date();
    var m = document.metadata;
    document.contentType = contentType;
    m.bucket = ns;
    m.na = na;
    m.fileSet = fileSet;
    m.pid = pid;
    if (lid) m.lid = lid;
    m.l = l;
    m.access = access;
    m.label = label;
    m.seq = seq;
    if (objid && objid.length != 0) m.objid = objid;
    if (embargo && embargo.length == 10) m.embargo = embargo;
    if (embargoAccess && embargoAccess.length != 0) m.embargoAccess = embargoAccess;

    m.resolverBaseUrl = resolverBaseUrl;
    m.timesUpdated = ( m.timesUpdated == undefined ) ? 0 : m.timesUpdated + 1;
    m.firstUploadDate = ( m.firstUploadDate == undefined ) ? now : m.firstUploadDate;
    m.lastUploadDate = now;
    m.timesAccessed = ( m.timesAccessed == undefined ) ? 0 : m.timesAccessed;
    if (content) m.content = content;

    if (ns == 'master') { // Ensure the master filename has an extension
        if (document.filename.indexOf(".") == -1) document.filename = appendExtension(document.filename, contentType);
    } else {// Ensure the derivative has an extension and inherits the master properties
        var master = db.master.files.findOne(query, {'metadata.content':0});
        document.filename = appendExtension(master.filename, contentType);
        m.l = master.metadata.l;
        m.access = master.metadata.access;
        if (master.metadata.embargo) m.embargo = master.metadata.embargo;
        if (master.metadata.embargoAccess) m.embargoAccess = master.metadata.embargoAccess;
        m.pidType = master.metadata.pidType;
        m.label = master.metadata.label;
        if (master.metadata.objid) m.objid = master.metadata.objid;
        if (master.metadata.seq) m.seq = master.metadata.seq;
    }

    files.save(document);
    assert(db.runCommand({getlasterror: 1, w: "majority"}).err == null, "Could not update metadata.");
    print('Update metadata ' + files.getName() + ' ' + document.metadata.pid);
    printjson(document);
}

var files = db.getCollection(ns + '.files');
var query = {'metadata.pid': pid};
var document = files.findOne(query);
assert(document.md5 == md5 && document.length == length, "Length and md5 do not match !");
metadata(document);
