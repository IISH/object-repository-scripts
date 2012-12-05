<?php

// f = csv file
// p = name of the pid key
// m = name of the master key

ini_set('auto_detect_line_endings', 1);

$options = getopt("f:p:m:", array("access:", "contentType:"));
if (!isset($options['f'])) {
    exit("file -f is not set\n");
}
$f = $options['f'];
echo "f=$f\n";
$fileSet = pathinfo($f, PATHINFO_DIRNAME);

$pidKey = "PID";
if (isset($options['p'])) {
    $pidKey = $options['p'];
}
$masterKey = "master";
if (isset($options['m'])) {
    $masterKey = $options['m'];
}

$instruction = $fileSet . '/instruction.xml';
$fh = fopen($instruction, 'w') or die("Cannot open file $instruction\n");

fwrite($fh, "<?xml version='1.0' encoding='UTF-8'?>\n");
fwrite($fh, "<!-- Instruction created on " . date("D M j G:i:s T Y") . " -->\n");
fwrite($fh, "<instruction xmlns='http://objectrepository.org/instruction/1.0/'");
foreach ($options as $key => $value) {
    fwrite($fh, " ");
    fwrite($fh, $key);
    fwrite($fh, "=");
    fwrite($fh, "'");
    fwrite($fh, $value);
    fwrite($fh, "'");
}
fwrite($fh, ">\n");

$handle = fopen($f, "r");
$header = fgetcsv($handle, 0, ",");

// Find the pid and the master index.
$index_pid = array_search($pidKey, $header);
$index_master = array_search($masterKey, $header);

if ($index_pid == -1) exit("$pidKey not present in header\n");
if ($index_master == -1) exit("$masterKey not present in header\n");

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
    $file = $basename . $location;
    $md5 = md5_file($file);
    $md5file = $file . '.md5';
    $md5handle = fopen($md5file, 'w') or die("Cannot open file $md5file\n");
    fwrite($md5handle, $md5 . '  ' . $file);
    fclose($md5handle);

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
