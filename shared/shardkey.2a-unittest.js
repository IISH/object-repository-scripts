/**
 * shardkey-2a-unittest.js
 *
 * Unit test for shardkey.2a.js
 *
 * Usage:
 * mongo test --eval "var lib_dir='/folder/to/js/" shardkey-2a-unittest.js
 **/

assert(db.getName() == 'test', 'Unit tests must be run from a test database.');

file_size = 1;
bucket = 'bucket';
db_shard = 'localhost:27017';
load(lib_dir + 'shardkey.2a.js');


var _c = CANDIDATE_LIMIT * 10;


// Setup up test collections.
clean();
setup();


function setup() {

    // Create 50 expired candidates

    var expired = new Date(new Date().getTime() - CANDIDATE_EXPIRED);
    for (var i = 1; i <= _c; i++) {
        var f = (i == _c) ? '' : i;
        var doc = {
            _id: 'localhost' + f + ':27017',
            active: true,
            setName: 'setName' + i,
            minkey: i,
            maxkey: i + 1431655766,
            version: 1,
            used: 10,
            avail: 20,
            usable: i,
            date: expired
        };
        db_shard_connection[HOST_DB_CANDIDATE].insert(doc);
    }
}

function clean() {
    db_shard_connection[HOST_DB_CANDIDATE].drop();
    db_shard_connection[HOST_DB_SEQUENCE].drop();
    db_shard_connection[HOST_DB_KEYS].drop();
    db_shard_connection.createCollection(HOST_DB_KEYS, { capped: true, size: 4096 });
    db[bucket + '.files'].drop();
    db[bucket + '.chunks'].drop();
}


print('test 1');
shardkey = 12345;
expect = db.getName() + '.' + bucket + '.12345';
compound_key = compoundKey(shardkey);
assert(compound_key == expect, 'Expect the namespaced shardkey to be ' + expect + ' but got ' + compound_key);


print('test 2');
assert(!listCandidates().length(), 'We expect zero candidates because there expired');


print('test 3');
db_shard_connection[HOST_DB_CANDIDATE].update({}, {$set: {date: new Date()}}, true, true);
assert(listCandidates().length() == CANDIDATE_LIMIT, 'We expect CANDIDATE_LIMIT candidates because there not expired');


print('test 4');
file_size = _c * GiB + GiB;
assert(!listCandidates().length(), 'No candidate expected able enough to store ' + file_size);


print('test 5');
file_size = _c * GiB;
var list_candidates = listCandidates();
assert(list_candidates.length() == 1, 'Only one candidate expected able enough to store ' + file_size);


print('test 6');
var candidate = list_candidates[0];
shardkey = getLastShardKey(candidate);
assert(candidate.minkey == shardkey, 'Expected shardkey to have a value of ' + candidate.minkey + ' but got ' + shardkey);


print('test 7');
var last_key = candidate.minkey + 1;
db[bucket + '.chunks'].save({n: 0, files_id: last_key});
shardkey = getLastShardKey(candidate);
assert(shardkey > candidate.minkey);
assert(last_key == shardkey, 'Expected shardkey to have a value of ' + last_key + ' but got ' + shardkey);


print('test 8');
for (shardkey = 0; shardkey < 10; shardkey++) {
    var compound_key = compoundKey(shardkey);
    assert(!db_shard_connection[HOST_DB_KEYS].findOne({_id: compound_key}));
    var available_shardkey = availableShardKey(shardkey);
    assert(available_shardkey == shardkey, 'Expected the candidate shardkey ' + shardkey + ' to be available, but got alternative ' + available_shardkey);
    assert(db_shard_connection[HOST_DB_KEYS].findOne({_id: compound_key}));
}


print('test 9');
shardkey = 10;
for (i = 0; i < RETRY_SHARDKEY; i++) {
    var expect = shardkey + i;
    available_shardkey = availableShardKey(shardkey);
    assert(available_shardkey == expect, 'Expected the available_shardkey to be ' + expect + ', but instead got ' + available_shardkey);
}


print('test 10');
try {
    var should_fail = availableShardKey(shardkey);
    assert(!should_fail, 'Expected an exception for shardkey ' + shardkey + ', but got ' + should_fail);
} catch (expected_this_error) {
    assert(expected_this_error.startsWith('Error: '));
}


print('test 11');
shardkey = 20;
for (i = 0; i < RETRY_SHARDKEY; i++) {
    expect = shardkey + 1;
    compound_key = compoundKey(expect);
    assert(!db_shard_connection[HOST_DB_KEYS].findOne({_id: compound_key}));
    db[bucket + '.files'].save({_id: shardkey});
    available_shardkey = availableShardKey(shardkey);
    assert(available_shardkey == expect, 'Expected the available_shardkey to be ' + expect + ', but instead got ' + available_shardkey);
    shardkey = available_shardkey + 1;
}


print('test 12');
assert(candidate.version == 1);
shardkey = printShardKey(); // should not throw an error


print('test 13');
candidate.version = 2;
db_shard_connection[HOST_DB_CANDIDATE].save(candidate);
for (expect = 202; expect < 500; expect++) { // the chunk was set by test 7 to 201.
    shardkey = printShardKey();
    assert(shardkey == expect, 'Expected a shardkey of ' + expect + ' but got ' + shardkey);
    db[bucket + '.files'].insert({_id: shardkey});
    db[bucket + '.chunks'].insert({n: 0, files_id: shardkey});
}


print('test 14');
candidate.minkey = 200000;
db_shard_connection[HOST_DB_CANDIDATE].save(candidate);
try {
    should_fail = printShardKey();
    assert(!should_fail, 'Expected an exception but got ' + should_fail);
} catch (expected_this_error) {
    assert(expected_this_error.startsWith('Error: '));
}


print('test 15');
candidate.minkey = 200;
candidate.maxkey = 199;
db_shard_connection[HOST_DB_CANDIDATE].save(candidate);
try {
    should_fail = printShardKey();
    assert(!should_fail, 'Expected an exception but got ' + should_fail);
} catch (expected_this_error) {
    assert(expected_this_error.startsWith('Error: '));
}


print('test 16');
file_size = 1;
clean();
setup();
var unique_list_of_candidates = [];
db_shard_connection[HOST_DB_CANDIDATE].update({}, {$set: {date: new Date()}}, true, true);
for (expect = 0; expect < CANDIDATE_LIMIT; expect++) {
    var host = getCandidate()._id;
    assert(unique_list_of_candidates.indexOf(host) == -1, 'Expected only single candidate entries but got another ' + host);
    unique_list_of_candidates.push(host);
}
assert(unique_list_of_candidates.length == CANDIDATE_LIMIT, 'Expected to have ' + CANDIDATE_LIMIT + ' elected candidates, but in stead got ' + unique_list_of_candidates.length);


clean();

