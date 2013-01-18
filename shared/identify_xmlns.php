<?php

/**
 * identify_xmlns
 *
 * Scans the XML document for used namespaces and returns them as JSON.
 */


// l = file location
$options = getopt("l:");
$l = $options['l'];

$xml = new DOMDocument();
$xml->load($l);

$sxe = new SimpleXMLElement($xml->saveXML());
$namespaces = $sxe->getNamespaces(true);
$a=array();
foreach ($namespaces as $prefix => $ns) {
    $prefix = str_replace(array("\n", "\r"), "", $prefix);
    $ns = str_replace(array("\n", "\r"), "", $ns);
    $a[]="'" . $prefix . "':'" . $ns . "'" ;
}
print("{" . implode(",", $a) . "}" );
?>