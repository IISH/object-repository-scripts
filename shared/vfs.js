/**
 vfs.js

 Construct a file system structure

 As each gridfs document will have:
 - A filename: file[.extension]
 - And a location l of the filename: /a/b/c/d/e/f/g

 Then to create the virtualfile system we rewrite file -l element to:
 /[na]/[bucket]/a/b/c/d/e/f/g/filename
 In case there is no -l element, we ignore the document

 Datestamps:
 Any datestamps expressed in the folder such as yyyy-MM-dd will be filtered out from the path

 Access:
 The meaning of the access status is first determined by looking at it's policy definition.
 Then it's first letter set to open, closed, or restricted: 'o', 'c' and 'r'

 **/

assert(db.getName().substring(0, 3) == "or_", "Need to be run on a database with name: or_[na]");
assert(ns, "Need a namespace\\bucket.");
var pid = ( pid === undefined ) ? null : pid;
var date = ( date === undefined ) ? null : date;

print('Create vfs for ' + db.getName() + '.' + ns);
var datestamp_pattern = /\/\d{4}-\d{2}-\d{2}\//;
var na = '/' + db.getName().substring(3) + '/';

var policies = [];db.getMongo().getDB('sa')['policy'].find({na:na}).forEach( function(d){ policies[d.access]=d } );
function access(a){
    policies.forEach(function(d){
           if (d.access == a )
               d.buckets.forEach(function(b){
                   if (b.bucket == ns) return b.access[0] ;
               })
    }) ;
    return 'c' ;
}

var query = ( pid ) ? {'metadata.pid':pid} : (date) ? {uploadDate:{$gt:ISODate(date)}} : {};
db.getCollection(ns + '.files').find(query, {'metadata.pid':1, 'metadata.l':1, filename:1, length:1, uploadDate:1, 'metadata.access':1}).forEach(
    function (d) {
        if (d.metadata.l) {
            var l = na + ns + d.metadata.l.replace(d.metadata.l.match(datestamp_pattern), '/');
            var parent = l;
            while ((i = parent.lastIndexOf("/")) > 0) {
                var child = parent;
                parent = parent.substring(0, i);
                var n = child.substring(i + 1);
                if (child == l)            // file
                    db.vfs.update({_id:child}, {$addToSet:{f:{n:d.filename, p:d.metadata.pid, l:d.length, t:d.uploadDate.getTime(), a:d.metadata.access[0]}}}, true, false);
                // folder
                db.vfs.update({_id:parent}, {$addToSet:{d:{n:n}}}, true, false);
            }
        }
    }
);
