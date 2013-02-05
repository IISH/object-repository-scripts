/**
 vfs.js

 from the vfs element contruct a folder structure

 Each master record will have:
 A filename: a[.extension]
 A fileSet: /a/b/c/[na]/[uploaderid]
 And a location l: /a/b/c/[na]/[uploaderid]/f/g/h

 The actual file that was uploaded is:
 l + "/" + filename
 **/

var na = '/' + db.getName().substring(3) + '/';
db.master.files.find({'metadata.fileSet':{$exists:true}}, {'metadata.l':1, filename:1, 'metadata.fileSet':1}).forEach(
    function (d) {
        var i = d.metadata.fileSet.indexOf(na);
        assert(i != -1, "No " + na + " in location");
        var l = (d.metadata.l) ? d.metadata.l.substring(i) : d.metadata.fileSet.substring(i);
        var split = l.split("/");
        var f = "";
        split.forEach(function (d) {
            f = f + "/" + d;
            if (f == l)
                db.vfs.update({_id:f}, {$inc:{f:1}}, true, false);
            else
                db.vfs.update({_id:f}, {$inc:{f:0}}, true, false);
        });
        db.vfs.update({_id:l}, {$inc:{f:1}}, true, false);
    })


