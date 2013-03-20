<?php

// f = csv file
// p = name of the pid key
// m = name of the master key
// s = name of the sequence key
// o = name of the METS objectid key
// n = the naming authority

ini_set('auto_detect_line_endings', 1);

$options = getopt("f:p:m:s:o:n:h:");

if (!isset($options['f'])) {
    exit("file -f is not set\n");
}

$f = $options['f'];
$fileSet = pathinfo($f, PATHINFO_DIRNAME);

$pidKey = "PID";
if (isset($options['p'])) {
    $pidKey = $options['p'];
}

$headers = "access='restricted' contentType='image/tiff'";
if (isset($options['h'])) {
    $headers = $options['h'];
}

$masterKey = "master";
if (isset($options['m'])) {
    $masterKey = $options['m'];
}

$na = (isset($options['n'])) ? $options['n'] : null;
$seqKey = "volgnr";
if (isset($options['s'])) {
    $seqKey = $options['s'];
    if ($na == null) {
        exit("na -n is not set\n");
    }
}

$objidKey = "ID";
if (isset($options['o'])) {
    $objidKey = $options['o'];
}

$instruction = $fileSet . '/instruction.xml';
$fh = fopen($instruction, 'w') or die("Cannot open file $instruction\n");

fwrite($fh, "<?xml version='1.0' encoding='UTF-8'?>\n");
fwrite($fh, "<!-- Instruction created on " . date("D M j G:i:s T Y") . " -->\n");
fwrite($fh, "<instruction xmlns='http://objectrepository.org/instruction/1.0/' " . $headers);
fwrite($fh, ">\n");

$handle = fopen($f, "r");
$header = fgetcsv($handle, 0, ",");

// Find the pid and the master index.
$index_pid = array_search($pidKey, $header);
$index_master = array_search($masterKey, $header);
if ($index_pid == -1) exit("$pidKey not present in header\n");
if ($index_master == -1) exit("$masterKey not present in header\n");

// Find the non obligatory values
$index_seq = array_search($seqKey, $header);
$index_objid = array_search($objidKey, $header);

print("header: ");
foreach ($header as $key) {
    echo " - " . $key;
}
print("\npid key: $pidKey at index $index_pid");
print("\nmaster key: $masterKey at index $index_master\n");


$basename = pathinfo($fileSet, PATHINFO_DIRNAME);
while (($data = fgetcsv($handle, 0, ",")) !== FALSE) {
    $pid = $data[$index_pid];
    $location = $data[$index_master];
    $seq = ($index_seq == -1) ? null : $data[$index_seq];
    $objid = ($index_objid == -1) ? null : $na . "/" . pathinfo($fileSet, PATHINFO_FILENAME) . "." . $data[$index_objid];
    $file = $basename . $location;
    $filename = pathinfo($location, PATHINFO_FILENAME);

    // First look for a md5 in a conventional place
    $md5FromFile = $fileSet . "/.Checksum/" . $filename;
    $md5 = getCustom($md5FromFile);
    if ($md5 == null) $md5 = md5_file($file);

    // Any alternative contentType or Access ?
    $access = getCustom(pathinfo($file, PATHINFO_DIRNAME) . '/.access.txt');
    $contentType = getCustom(pathinfo($file, PATHINFO_DIRNAME) . '/.contentType.txt');

    print("Add stagingfile " . $file . " - " . $md5 . " - " . $pid . "\n");
    fwrite($fh, "    <stagingfile>\n");
    fwrite($fh, "        <pid>" . $pid . "</pid>\n");
    fwrite($fh, "        <location>" . $location . "</location>\n");
    fwrite($fh, "        <md5>" . $md5 . "</md5>\n");
    if ($access) fwrite($fh, "        <access>" . $access . "</access>\n");
    if ($contentType) fwrite($fh, "        <contentType>" . $access . "</contentType>\n");
    if ($seq) fwrite($fh, "        <seq>" . $seq . "</seq>\n");
    if ($objid) fwrite($fh, "        <objid>" . $objid . "</objid>\n");
    fwrite($fh, "    </stagingfile>\n");
}

fwrite($fh, '</instruction>');
fclose($fh);

function getCustom($override)
{
    $text = null;
    if (file_exists($override)) {
        $handle = fopen($override, 'r') or die("Cannot open file $override\n");
        $text = fread($handle, filesize($override));
        fclose($handle);
    }
    return $text;
}

?>