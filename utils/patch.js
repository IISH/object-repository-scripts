var list = [];
var listmets = [];
var na = '/' + db.getName().substring(3);

if (db.getName() == 'or_10622') {

    db.master.files.find({'metadata.fileSet':{$exists:true}}, { filename:1, contentType:1, 'metadata.label':1, 'metadata.fileSet':1, uploadDate:1, 'metadata.pid':1, 'metadata.access':1}).forEach(function (d) {
        var p = d.metadata.pid.substring(6);
        var l = null;
        if (p.indexOf('30051') == 0) {
            var fileSet = '/mnt/sa/10622/12347/2013-02-21';
            l = '/2013-02-21/' + p.substring(0, 5) + '/' + p.substring(5, 7) + '/' + p.substring(7, 10);
            list.push({p:d.metadata.pid, fileSet:fileSet, l:l, f:d.filename, c:d.contentType, a:d.metadata.access});
        } else {
            var i = d.filename.indexOf('_');
            if (i == -1) {
                l = d.metadata.fileSet.substring(d.metadata.fileSet.lastIndexOf('/'));
                list.push({p:d.metadata.pid, fileSet:d.metadata.fileSet, l:l, f:d.filename, c:d.contentType, a:d.metadata.access});
            } else {
                l = d.metadata.fileSet.substring(d.metadata.fileSet.lastIndexOf('/')) + '/' + d.filename.substring(0, i);
                var j = d.filename.lastIndexOf(".");
                var seq = Number(d.filename.substring(i + 1, j));
                i = d.metadata.fileSet.lastIndexOf('/');
                var objid = "10622" + d.metadata.fileSet.substring(i);
                listmets.push({p:d.metadata.pid, fileSet:d.metadata.fileSet, l:l, objid:objid, seq:seq, f:d.filename, c:d.contentType, a:d.metadata.access})
            }
        }
    });
} else {
    db.master.files.find({}, { filename:1, contentType:1, 'metadata.label':1, 'metadata.fileSet':1, 'metadata.l':1, 'metadata.pid':1, 'metadata.access':1}).forEach(function (d) {
        var fileSet = (d.metadata.fileSet) ? d.metadata.fileSet : "/mnt/sa" + na + na + '/' + d.metadata.label;
        var folder = fileSet.substring(fileSet.lastIndexOf("/") + 1);
        var l = (d.metadata.l) ? d.metadata.l.substring(19) : "/" + folder;
        if (db.getName() == 'or_10851') {
            var i = d.filename.indexOf('_');
            var j = d.filename.indexOf("_", i+1);
            l = '/' + d.filename.substring(0,i) + '/' +d.filename.substring(i + 1, j);
            fileSet = '/mnt/sa/10851/10851' + l;
        }
        list.push({p:d.metadata.pid, fileSet:fileSet, l:l, f:d.filename, c:d.contentType, a:d.metadata.access});
    });
}

['master', 'level1', 'level2', 'level3'].forEach(function (ns) {
    var collection = db.getCollection(ns + '.files');
    print("Updating list " + ns);
    list.forEach(function (d) {
        var query = {'metadata.pid':d.p};
        var contentTypeBucket = collection.findOne(query, {contentType:1});
        if (contentTypeBucket) {
            var f = getFilename(ns, d.p, d.f, contentTypeBucket.contentType);
            //printjson(j);
            collection.update(query, {$set:{filename:f, 'metadata.fileSet':d.fileSet, 'metadata.l':d.l, 'metadata.access':d.a}}, false, false);
            //assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not update metadata.");
        }
    });


    print("Updating listmets");
    listmets.forEach(function (d) {
        var query = {'metadata.pid':d.p};
        var contentType = collection.findOne(query, {contentType:1});
        if (contentType) {
            var f = getFilename(ns, d.p, d.f, contentType.contentType);
            //printjson(j);
            collection.update({'metadata.pid':d.p}, {$set:{filename:f, 'metadata.fileSet':d.fileSet, 'metadata.l':d.l, 'metadata.access':d.a, 'metadata.objid':d.objid, 'metadata.seq':d.seq}}, false, false);
            //assert(db.runCommand({getlasterror:1, w:"majority"}).err == null, "Could not update metadata.");
        }
    });
});

function getFilename(ns, p, f, c) {
    if (ns == 'master') { // Ensure the master filename has an extension
        if (f.indexOf(".") == -1) return appendExtension(f, c);
        return f;
    }

    var master = db.master.files.findOne({'metadata.pid':p}, {filename:1});
    return appendExtension(master.filename, c);
}

function appendExtension(filename, contentType) {
    var i = contentType.indexOf('/');
    var extension = (i == -1) ? 'bin' : contentType.substring(i + 1);
    i = filename.lastIndexOf('.');
    var f = (i == -1) ? filename : filename.substring(0, i);
    return f + '.' + extension;
}

