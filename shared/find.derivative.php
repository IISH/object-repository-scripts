<?php

/**
 * findderivative.php
 *
 * See if we can find a ready, custom made derivative on a conventional place.
 *
 * Given a master's location: [master folder]/[filename master][.[extension master]]
 * expressed as: DIR/FILE.EXT ( e.g. /a/b/c/d/mymaster.tiff )
 * That is:
 * DIR(folder)=/a/b/c/d
 * FILE(filename)=mymaster
 * EXT(extension)=.tiff
 *
 * We accept any of the following two formats:
 * 1. as subdirectory in the folder that contains the master
 * 2. as a directory that has substituted any of the the parent folders that contains the master
 *
 * Examples 1:
 * /a/b/c/d/mymaster.tiff
 * /a/b/c/d/.level1/mymaster.png
 * /a/b/c/.level1/mymaster.png
 * /a/b/.level1/d/mymaster.png
 * /a/.level1/c/d/mymaster.png
 * /.level1/a/b/c/d/mymaster.png
 *
 * More practical example 2:
 * /a folder/TIFF/005/mymaster.tif
 * /a folder/.level2/005/mymaster.jpg
 *
 * Another practical example 3:
 * /a folder/TIFF/005/mymaster.tif
 * /a folder/TIFF/005/.level2/mymaster.jpg
 *
 * Approach
 * Rather than iterating over the folders,
 * we will substitute each master subfolder with the requested bucket level
 * and see if we discover a corresponding file.
 **/

// f = fileset, l = master file and b = bucket\derivative
$options = getopt("l:b:f:");
$l = $options['l'];
$b = $options['b'];
$f = $options['f'];
print(findLevel($f, $l, $b, pathinfo($l, PATHINFO_FILENAME)));

function findLevel($fileSet, $location, $bucket, $filename)
{
    $pieces = explode("/", $location);
    $start = sizeof(explode("/", $fileSet));
    $length = sizeof($pieces);
    for ($i = $start; $i < $length; $i++) {

        $insert = "";
        for ($j = $start; $j < $i; $j++) {
            if (!empty($pieces[$j])) $insert .= "/" . $pieces[$j];
        }
        $insert .= "/" . $bucket;
        $substitute = $insert;
        for ($j = $i; $j < $length - 1; $j++) {
            if (!empty($pieces[$j])) {
                $insert .= "/" . $pieces[$j];
                if ($j != $i) $substitute .= "/" . $pieces[$j];
            }
        }

        $files = rglob(escape($fileSet . $insert), escape($filename) . ".*");
        if (sizeof($files) != 0) return $files[0];
        $files = rglob(escape($fileSet . $substitute), escape($filename) . ".*");
        if (sizeof($files) != 0) return $files[0];
    }
    return NULL;
}

function escape($text){
    return preg_replace('/(\*|\?|\[)/', '[$1]', $text);
}


/*
* @return array containing all pattern - matched files .
*
* @param string $sDir      Directory to start with .
* @param string $sPattern  Pattern to glob for.
* @param int $nFlags       Flags sent to glob .
*/
function rglob($sDir, $sPattern, $nFlags = NULL)
{
    // Get the list of all matching files currently in the
    // directory.
    $filter = "$sDir/$sPattern";
    return glob($filter, $nFlags);
}

?>
