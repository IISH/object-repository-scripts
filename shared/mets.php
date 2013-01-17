<?php

// l = file location
$options = getopt("l:");
$l = $options['l'];

$xml = new DOMDocument();
$xml->load($l);

$xpath = new DOMXPath($xml);
$xpath->registerNamespace('mets', 'http://www.loc.gov/METS/');

$mets = $xpath->evaluate('//mets:mets');
$count = $mets->length;
if ( $count == 0 ) {
	print("false");
} else {
	print "true";
}

?>

