/**
 vfs.js

 Construct a file system structure

 Each master record will have:
 A filename: a[.extension]
 A fileSet: /a/b/c/[na]/[uploaderid]
 And a location l: /a/b/c/[na]/[uploaderid]/f/g/h
 The actual file that was uploaded is:
 l + "/" + filename
 In legacy cases there is no l key. Here we fall back on the fileSet.

 To create the virtualfile system we offer:
 /[na]/[uploaderid]/[l]/[filename]
 **/

assert(db.getName().substring(0, 3) == "or_", "Need to be run on a database with name: or_[na]");
var na = '/' + db.getName().substring(3) + '/';

db.master.files.find({'metadata.fileSet':{$exists:true}}, {'metadata.l':1, filename:1, 'metadata.fileSet':1}).forEach(
    function (d) {
        var i = d.metadata.fileSet.indexOf(na);
        assert(i != -1, "No " + na + " in fileSet");
        var l = (d.metadata.l) ? d.metadata.l.substring(i) : d.metadata.fileSet.substring(i);     // /[na]/[uploaderid]/[l]/[filename]
        // /[na]/[uploaderid]/[l]/[bucket]/[filename]
        db.vfs.update({_id:l}, {$inc:{c:1}, $push:{f:d.filename, f:length}}, true, false);
        while ((i = l.lastIndexOf("/")) > 0) {
            var d = l;
            l = l.substring(0, i);
            if (d == d.metadata.l)            // file
                db.vfs.update({_id:l}, {$pop:{f:{f:d.filename, l:d.length}}}, true, false);
            else                                     // folder
                db.vfs.update({_id:l}, {$pop:{d:d}}, true, false);
        }
    });