/**
 * content.js
 *
 * Usage: mongo [database] --quiet --eval "var ... content parameters"
 **/

assert(content, "Content must be set to a json variable");

var files = db.getCollection(ns + '.files');
files.update({pid:pid}, {$set:{'metadata.content':content}}, false, false);
