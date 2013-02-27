/**
 vfs.js

 Construct a file system structure

 Each master record will have:
 A filename: file[.extension]
 And a location l of the filename: /a/b/c/d/e/f/g

 To create the virtualfile system we rewrite file -l element to:
 /[na]/[bucket]/a/b/c/d/e/f/g/filename
 In case there is no -l element, we ignore the document

 Datestamps:
 Any datestamps expressed in the folder such as yyyy-MM-dd will be filtered out from the path

 **/

assert(db.getName().substring(0, 3) == "or_", "Need to be run on a database with name: or_[na]");
assert(ns, "Need a namespace\\bucket.");
assert( pid !== undefined, "Need a defined pid value: null or anything else");

if ( ns=='master' && !pid ) {
    print('Clearing vfs');
    db.vfs.remove();
}
print('Create vfs for ' + db.getName() + '.' + ns);

var datestamp_pattern = /\/\d{4}-\d{2}-\d{2}\//;

var na = '/' + db.getName().substring(3) + '/';
var query = ( pid ) ? {'metadata.pid':pid} : {'metadata.fileSet':{$exists:true}};
db.getCollection(ns + '.files').find(query, {'metadata.pid':1, 'metadata.l':1, filename:1, length:1, uploadDate:1}).forEach(
    function (d) {
        if (d.metadata.l) {
            var l = na + ns + d.metadata.l.replace(d.metadata.l.match(datestamp_pattern), '/');
            var parent = l;
            while ((i = parent.lastIndexOf("/")) > 0) {
                var child = parent;
                parent = parent.substring(0, i);
                var n = child.substring(i + 1);
                if (child == l)            // folder of file
                    db.vfs.update({_id:child}, {$addToSet:{f:{n:d.filename, p:d.metadata.pid, l:d.length, t: d.uploadDate.getTime()}}}, true, false);
                // folder
                db.vfs.update({_id:parent}, {$addToSet:{d:{n:n}}}, true, false);
            }
        }
    }
);