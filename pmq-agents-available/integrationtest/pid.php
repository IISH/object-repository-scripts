<?php

// l = file location; p=pid
$options = getopt("l:");
$l = $options['l'];

$xml = new DOMDocument();
$xml->load($l);

$xpath = new DOMXPath($xml); 
$xpath->registerNamespace('pid', 'http://pid.socialhistoryservices.org/');
$xpath->registerNamespace('SOAP-ENV', 'http://pid.socialhistoryservices.org/');

$pid = $xpath->evaluate('//pid:pid/text()');
$count = $pid->length;
if ( $count == 0 ) {
	print("null");
} else {
	print $pid->item(0)->nodeValue;
}
?>

