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

// l = file with extension and t = file of content types
$options = getopt("l:t:");
$l = $options['l'];
$t = $options['t'];
$contentType = "application/octet-stream";

$extension = "." . pathinfo($l, PATHINFO_EXTENSION);
if ($extension == ".") {
    echo $contentType;
    exit(0);
}

$file = fopen($t, "r") or exit("Unable to open file!");
while (!feof($file)) {
    $line = fgets($file);
    if ($line[0] == "#") continue;
    $split = preg_split("/[\\s,]+/", $line, 2);
    if ($split[0] == strtolower($extension)) {
        $contentType = trim($split[1]);
    }
}
fclose($file);

echo $contentType;

?>