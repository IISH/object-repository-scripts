<?php

/*
 * contenttype
 *
 * We suggest a content type or mime type of a file by making a comparison with the extension and
 * the often used association with a mimetype.
 *
 * The first match in the list is returned.
 * No matches results in returning the last item in the content list
 */

// c = contentType and t = file that contains extensions and content types
$options = getopt("c:t:");
$c = $options['c'];
$t = $options['t'];

$contentType="bin";
$file = fopen($t, "r") or exit("Unable to open file $t!");
while (!feof($file)) {
    $line = trim(fgets($file));
    if ($line[0] == "#") continue;
    $split = preg_split("/[\\s,]+/", $line, 2);
    if ($split[1] == strtolower($c)) {
        $contentType = trim($split[0]);
        break;
    }
}
fclose($file);

echo $contentType;

?>
