<?php

/**
 * Ensure utf8 encoding and removal of /n/r
 */

$options = getopt("i:");
if (isset($options['i'])) {
    $i = preg_replace("(\r|\n)", "", $options['i']);
    print(utf8_encode($i));
}
?>
