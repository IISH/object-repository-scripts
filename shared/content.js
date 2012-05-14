/**
 * content.js
 *
 * Usage: mongo [database] --quiet --eval "var ... content parameters"
 **/

assert(content, "Content must be set to a json variable");
assert(pid, "Need a pid value");
assert(ns, "Need a bucket namespace");

var files = db.getCollection(ns + '.files');
files.update({'metadata.pid':pid}, {$set:{'metadata.content':content}}, false, false);
