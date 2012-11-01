<?php

/**
 * shardkey.php
 *
 * Return a simple random ranged key value within the integer 32 bit range
 */

// s = number of shards. p = preferred shard range [0..n-1].
$options = getopt("s:p:");
$p = $options['p'];
$s = $options['s'];

// Assume a range of Integer 32
$max = 4294967296;
$min = -2147483648;
$range = floor($max / $s);

echo rand($min + $p * $range, $min + ($p + 1) * $range);

?>