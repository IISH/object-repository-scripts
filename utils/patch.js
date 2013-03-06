function ISODateString(d) {
    function pad(n) {
        return n < 10 ? '0' + n : n
    }

    return d.getUTCFullYear() + '-'
        + pad(d.getUTCMonth() + 1) + '-'
        + pad(d.getUTCDate()) + 'T'
        + pad(d.getUTCHours()) + ':'
        + pad(d.getUTCMinutes()) + ':'
        + pad(d.getUTCSeconds()) + 'Z'
}

var list=[];
var listmets=[];

db.master.files.find({'metadata.fileSet':{$exists:true}}, { filename:1, 'metadata.fileSet':1, uploadDate:1, 'metadata.pid':1}).forEach(function (d) {
    var p = d.metadata.pid.substring(6);
    var l = null;
    var date = ISODateString(d.uploadDate);
    if (p.indexOf('30051') == 0) {
        var datestamp = date.substring(0,10);
        var fileSet = '/mnt/sa/10622/12347/' + datestamp;
        l = '/' + datestamp + '/' + p.substring(0, 5) + '/' + p.substring(5, 7) + '/' + p.substring(7, 10);
        list.push({p:d.metadata.pid, fileSet:fileSet, l:l});
    } else {
        var i = d.filename.indexOf('_');
        if (i != -1) {
            var item = d.filename.substring(0, i);
            l = d.metadata.fileSet.substring(d.metadata.fileSet.lastIndexOf('/')) + '/' + item;
            var j = d.filename.lastIndexOf(".");
            var seq = Number(d.filename.substring(i + 1, j));
            i = d.metadata.fileSet.lastIndexOf('/');
            var objid = '10622/' + l.substring(1, 10) + '.' + item;
            listmets.push({p:d.metadata.pid, fileSet:d.metadata.fileSet, l:l, objid:objid})
        }
    }
});

['master', 'level1', 'level2', 'level3'].forEach(function (ns) {
    var collection = db.getCollection(ns + '.files');
    print("Updating list " + ns);
    list.forEach(function (d) {
        //printjson(d);
        collection.update({'metadata.pid':d.p}, {$set:{'metadata.fileSet':d.fileSet,'metadata.l':d.l}}, false, false);
    });


    print("Updating listmets");
    listmets.forEach(function (d) {
        printjson(d);
        collection.update({'metadata.pid':d.p}, {$set:{ 'metadata.l':d.l, 'metadata.objid':d.objid}}, false, false);
    });
});