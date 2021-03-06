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
var log = ( log === undefined ) ? null : log;
var pid = ( pid === undefined ) ? null : pid;
var date = ( date === undefined ) ? null : date;
var del = ( del === undefined ) ? false : del;
var environment = ( environment === undefined ) ? 'production' : 'test' ;

print('Create vfs for ' + db.getName() + '.' + ns);
var datestamp_pattern = /\/\d{4}-\d{2}-\d{2}\//;
var na = '/' + db.getName().substring(3) + '/';

var query = ( pid ) ? {'metadata.pid': pid} : (date) ? {uploadDate: {$gt: ISODate(date)}} : {};

function update(d, name, access, uploadDate) {
    d.n = name;
    if (access) {
        if (!d.a)
            d.a = [access];
        else if (d.a.indexOf(access) == -1)
            d.a.push(access);
    }
    d.t = ( d.t && d.t > uploadDate) ? d.t : uploadDate;

    return d;
}

var count = 0;
db.getCollection(ns + '.files').find(
    query,
    {'metadata.pid': 1, 'metadata.objid': 1, 'metadata.l': 1, filename: 1, length: 1, uploadDate: 1, 'metadata.access': 1}).sort({'metadata.objid': 1})
    .addOption(DBQuery.Option.noTimeout)
    .forEach(
    function (d) {
        if (d.metadata.l && d.metadata.pid) {
            print(++count + '. ' + ns + ' ' + d.metadata.pid);
            var l = na + ns + d.metadata.l.replace(d.metadata.l.match(datestamp_pattern), '/');
            var parent = l;
            while ((i = parent.lastIndexOf('/')) > 0) {
                var child = parent;
                parent = parent.substring(0, i);
                var n = child.substring(i + 1);
                if (log) {
                    if (del)
                        print('Unset from parent ' + parent + ' child ' + n);
                    else
                        print('Set parent ' + parent + ' and child ' + n);
                }

                // file
                if (child == l) {
                    var _f = {n: d.filename, p: d.metadata.pid, l: d.length, t: d.uploadDate.getTime(), a: d.metadata.access};
                    if (d.metadata.objid)
                        _f.o = d.metadata.objid;
                    if (del)
                        db.vfs.update({_id: child}, {$pull: {f: _f}}, true, false);
                    else
                        db.vfs.update({_id: child}, {$addToSet: {f: _f}}, true, false);
                    if ( environment == 'production' ) assert(db.runCommand({getlasterror: 1, w: '2'}).err == null, "Could not update vfs.");
                }

                // folder
                var doc = db.vfs.findOne({_id: parent});
                if (doc && doc.d) {
                    for (D = 0; D <= doc.d.length; D++) {
                        if (D == doc.d.length) {
                            if (log) print(count + ' new sub directory ' + n + ' in parent ' + parent + ' in ' + l);
                            doc.d.push(update({}, n, d.metadata.access, d.uploadDate.getTime()));
                            db.vfs.save(doc);
                            if ( environment == 'production' ) assert(db.runCommand({getlasterror: 1, w: '2'}).err == null, "Could not update vfs.");
                            break;
                        }
                        else if (doc.d[D].n == n) {
                            if (!doc.d[D].a || doc.d[D].a.indexOf(d.metadata.access) == -1) {
                                update(doc.d[D], n, d.metadata.access, d.uploadDate.getTime());
                                if (log) print(count + ' existing sub directory ' + n + ' in parent ' + parent + ' in ' + l);
                                db.vfs.save(doc);
                                if ( environment == 'production' ) assert(db.runCommand({getlasterror: 1, w: '2'}).err == null, "Could not update vfs.");
                            }
                            break;
                        }
                    }
                }
                else {
                    if (log) print(count + ' new directory ' + parent);
                    db.vfs.save({_id: parent, d: [
                        update({}, n, d.metadata.access, d.uploadDate.getTime())
                    ]});
                    if ( environment == 'production' ) assert(db.runCommand({getlasterror: 1, w: '2'}).err == null, "Could not update vfs.");
                }
            }
        }
    }
);
