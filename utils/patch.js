assert(ns, 'must have ns');

var collection = db.getCollection(ns + '.files');

var list = [];
if (db.getName() == 'or_10622') {
    collection.find({uploadDate:{$lt:ISODate('2013-03-05')}}, { 'metadata.l':1, 'metadata.objid':1}).forEach(function (d) {
        if (d.metadata.objid && d.metadata.objid.indexOf('ARCH') != -1) {
            var i = d.metadata.l.lastIndexOf('/');
            if (i != -1) {
                var objid = '10622' + d.metadata.l.substring(0, i) + '.' + d.metadata.l.substring(i + 1);
                list.push({_id:d._id, o:objid});
            }
        }
    });
}

list.forEach(function (d) {
    collection.update({_id:d._id}, {$set:{'metadata.objid':d.o}}, false, false);
});