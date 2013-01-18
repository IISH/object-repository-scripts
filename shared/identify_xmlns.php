<?php
// l = file location
$options = getopt("l:");
$l = $options['l'];

$xml = new DOMDocument();
$xml->load($l);

$sxe = new SimpleXMLElement($xml->saveXML());
$namespaces = $sxe->getNamespaces(true);
print("{");
foreach ($namespaces as $prefix => $ns) {
    $prefix = str_replace(array("\n", "\r"), "", $prefix);
    $ns = str_replace(array("\n", "\r"), "", $ns);
    print("'" . $prefix . "':'" . $ns . "'") ;
}
print("}");
?>