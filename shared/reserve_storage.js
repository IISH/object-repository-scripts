/**
 * reserveshard.js
 *
 * Before we write; we reserve the space needed to store the intended file.
 * And once a file is stored we like to remove that reservation.
 *
 * @shardkey
 * The shardkey which determined the candidate shard.
 *
 * @file_size
 * The length of the file in bytes. Minus to undo a reservation.
 **/

var HOST_DB_NAME = 'shard';
var HOST_DB_CANDIDATE = 'candidate';
var GiB = 1073741824;


assert(db.getName() == HOST_DB_NAME, 'Must connect to the shard database.');
assert(shardkey, 'Must have a shardkey: var shardkey=shardkey"');
assert(file_size, 'File size needed: var file_size=NumberLong(\'12345\');');


function reserveShard() {
    var reserved = Math.ceil(Math.abs(file_size) / GiB);
    if (file_size < 0) reserved = -reserved;
    db[HOST_DB_CANDIDATE].update({minkey: {$lte: shardkey}, maxkey: {$gte: shardkey}}, {$inc: {reserved: reserved, usable: -reserved}}, false, false);
}

reserveShard();