<?php

// c = location of the csv file
// i = instruction file
// f = fileSet
// p = index position of the PID ( starting from zero )
// m = index position of the Master file ( starting from zero )

$options = getopt("c:i:f;");
$csv =         $options['c'];
$instruction = $options['i'];
$fileSet =     $options['f'];
$p =           $options['p'];
$m =           $options['m'];
echo "csv=$csv";
echo "instruction=$instruction";
echo "fileSet=$fileSet";
echo "pid=$p";
echo "master=$m";

$fh = fopen($instruction, 'w') or die("Cannot open file $instruction");

fwrite($fh, "<instruction xmlns='http://objectrepository.org/instruction/1.0/'>");

$handle = fopen($csv, "r");
$header = fgetcsv($handle, 0, ",");

// Find the pid and the master position
$keys = fgetcsv($handle, 0, ",")


while (($data = fgetcsv($handle, 0, ",")) !== FALSE) {
    $pid=$data[0];
    $location=$data[1];
    $file = $fileSet . "/" . $location;
    
    $md5 = md5_file($file);
    $md5file=$file . 'md5';
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
