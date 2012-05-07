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
$f = dirname($options['f']);

print( findLevel($f, 10, dirname($l), pathinfo($l, PATHINFO_FILENAME), $b) );

function findLevel($f, $failSave, $folder, $filename, $bucket)
{
    if ($f == $folder || $failSave < 1) return null;

    $files = rglob($folder . "/." . $bucket, $filename . ".*");
    if (sizeof($files) == 0) {
        return findLevel($f, $failSave - 1, dirname($folder), $filename, $bucket);
    }
    if (sizeof($files) == 1) return $files[0];
    return null;
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
    //echo "filter:" . $filter . "\n";
    return glob($filter, $nFlags);
}

?>