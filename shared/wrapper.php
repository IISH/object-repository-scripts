<?php

/**
 * Ensure utf8 encoding and removal of \r \n
 */

// Report simple running errors
error_reporting(E_ERROR | E_PARSE);

$options = getopt("i:");
if (isset($options['i'])) {
    $fh = fopen($options['i'], 'r');
    $data = fread($fh, filesize($options['i']));
    fclose($fh);
    print(preg_replace("(\r|\n|\t)", "", utf8_encode($data)));
}
?>
