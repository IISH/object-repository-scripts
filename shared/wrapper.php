<?php

/**
 * Ensure utf8 encoding and removal of \r \n
 * Ensure the quotes are escaped. We need that for our json paring.
 */

// Report simple running errors

error_reporting(E_ERROR | E_PARSE);

$options = getopt("i:o:");
if (isset($options['i'])) {
    $fr = fopen($options['i'], 'r');
    $data = preg_replace("(\r|\n|\t)", "", utf8_encode(fread($fr, filesize($options['i']))));
    $data = preg_replace("(\")", "\"\"", $data);
    $data = preg_replace("(')", "''", $data);
    fclose($fr);
    if (isset($options['o'])) {
        $fw = fopen($options['o'], 'w');
        fwrite($fw, $data);
        fclose($fw);
    } else print($data);
}
?>