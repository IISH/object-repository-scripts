<?php

// c = location of the csv file
// i = instruction file
// f = fileSet
// p = index position of the PID ( starting from zero )
// m = index position of the Master file ( starting from zero )

$options = getopt("f:");
if (!isset($options['f'])) {
    exit("fileSet -f is not set");
}
$fileSet = $options['f'];
echo "fileSet=$fileSet";

$instruction = $fileSet . '/instruction.xml';
$fh = fopen($instruction, 'w') or die("Cannot open file $instruction");

fwrite($fh, "<instruction xmlns='http://objectrepository.org/instruction/1.0/'>");

$csv = $fileSet . "/" . pathinfo($fileSet, PATHINFO_BASENAME) . ".csv";
$handle = fopen($csv, "r");
$header = fgetcsv($handle, 0, ",");

// Find the pid and the master position
$keys = fgetcsv($handle, 0, ",");
$index_pid = -1;
$index_master = -1;
for ($i = 0; $i < sizeof($keys); $i++) {
    if ($keys[$i] == 'pid') $index_pid = $i;
    if ($keys[$i] == 'master') $index_master = $i;
}

if ($index_pid == -1) exit("pid key not present in header");
if ($index_master == -1) exit("master key not present in header");

while (($data = fgetcsv($handle, 0, ",")) !== FALSE) {
    $pid = $data[$index_pid];
    $location = $data[$index_master];
    $file = $fileSet . "/" . $location;

    $md5 = md5_file($file);
    $md5file = $file . 'md5';
    fopen($md5file, 'w') or die('Cannot open file $md5file');
    fwrite($md5file, $md5 . '  ' . $file);
    fclose($md5file);

    fwrite($fh, '    <stagingfile>');
    fwrite($fh, '        <pid>' . $pid . '</pid>');
    fwrite($fh, '        <location>' . $location . '</location>');
    fwrite($fh, '        <md5>' . $md5 . '</md5>');
    fwrite($fh, '    </stagingfile>');
}

fwrite($fh, '</instruction>');
fclose($fh);

?>
