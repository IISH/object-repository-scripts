<?php

// Returns the appropriate conversion command given the input file and desired derivative format.

ini_set("memory_limit", "2048M"); //SET THE MEMORY LIMIT TO 2GiB

//DEFINE DIFERENT DERIVATIVE TYPES
$derivativeTypes = array();

//MULTIDIMENSIONAL ARRAY WITH ALL DERIVATIVE TYPES

// 'encode' AND 'extension' ARE THE ONLY MANDATORY VALUES - FOR THE VALUES OF 'encode' RUN 'convert -list compress'
// IF YOU DEFINE 'targetDPI' THEN 'higher', 'lower' AND 'target' ARE MANDATORY
// ['targetDPI'][n]['target'] ACCEPTS INT VALUES AND 2 STRINGS : 'equal' AND 'half'

// 'maxWidth' AND 'maxHeight' OVERRIDE 'targetDPI' RULES BUT DOES THE RESIZE BASED ON DPIS - PXS VALUES WILL NOT PRECISE (BECAUSE OF THE FLOOR ON DPIS) BUT ALWAYS LOWER THEN THE DEFINED 'maxWidth' AND 'maxHeight'

// 'forceLength' OVERRIDE ALL OTHER RESIZE OPTIONS AND SHOULD ONLY BE USED FOR GENERANTING THUMBS D3 - RESIZE IS NOT BASED ON DPIS (DPIS ARE DEFAULTED TO 72)


//D1
$derivativeTypes['level1']['encode'] = 'JPEG';
$derivativeTypes['level1']['extension'] = 'jpg';
$derivativeTypes['level1']['quality'] = 45;


//D2
/*$derivativeTypes['d2']['targetDPI'][0]['higher'] = 0;
$derivativeTypes['d2']['targetDPI'][0]['lower'] = 200;
$derivativeTypes['d2']['targetDPI'][0]['target'] = 'equal';

$derivativeTypes['d2']['targetDPI'][1]['higher'] = 200;
$derivativeTypes['d2']['targetDPI'][1]['lower'] = 400;
$derivativeTypes['d2']['targetDPI'][1]['target'] = 200;

$derivativeTypes['d2']['targetDPI'][2]['higher'] = 400;
$derivativeTypes['d2']['targetDPI'][2]['lower'] = 99999;
$derivativeTypes['d2']['targetDPI'][2]['target'] = 'half';

$derivativeTypes['d2']['encode'] = 'JPEG';
$derivativeTypes['d2']['extension'] = 'jpg';
$derivativeTypes['d2']['quality'] = 35;*/


//D2 OSA
$derivativeTypes['level2']['targetDPI'][0]['higher'] = 0;
$derivativeTypes['level2']['targetDPI'][0]['lower'] = 200;
$derivativeTypes['level2']['targetDPI'][0]['target'] = 'equal';

$derivativeTypes['level2']['targetDPI'][1]['higher'] = 200;
$derivativeTypes['level2']['targetDPI'][1]['lower'] = 400;
$derivativeTypes['level2']['targetDPI'][1]['target'] = 200;

$derivativeTypes['level2']['targetDPI'][2]['higher'] = 400;
$derivativeTypes['level2']['targetDPI'][2]['lower'] = 99999;
$derivativeTypes['level2']['targetDPI'][2]['target'] = 'half';

$derivativeTypes['level2']['maxWidth'] = 1500; //PX
$derivativeTypes['level2']['maxHeight'] = 1500; //PX

$derivativeTypes['level2']['encode'] = 'JPEG';
$derivativeTypes['level2']['extension'] = 'jpg';
$derivativeTypes['level2']['quality'] = 35;


//D3
$derivativeTypes['level3']['encode'] = 'JPEG';
$derivativeTypes['level3']['extension'] = 'jpg';
$derivativeTypes['level3']['quality'] = 25;
$derivativeTypes['level3']['forceLength'] = 450; //PX


function generateDerivative($input, $derivativeType, $output)
{
    global $derivativeTypes;


    //GET INFO FROM INPUT FILE
    try {
        $im = new Imagick($input);
    } catch (Exception $e) {
        echo "ERROR: " . $e->getMessage() . "\n";
        exit(1);
    }

    $original['dpis'] = $im->getImageResolution();
    $original['dpisUnit'] = $im->getImageUnits();
    $dpisx=(int)round($original['dpis']['x']);
    $dpisy=(int)round($original['dpis']['y']);

    if ($original['dpisUnit'] == 2) {
        $original['dpis'] = (int)round($original['dpis']['x'] * 2.54237);
    } else {
        $original['dpis'] = (int)$original['dpis']['x'];
    }

    $original['px'] = $im->getImageGeometry();
    $original['depth'] = $im->getImageDepth();

    $targetDPIs = $original['dpis'];
    $targetWidth = $original['px']['width'];
    $targetHeight = $original['px']['height'];

    //PARSE DPIs RULES
    if (isset($derivativeTypes[$derivativeType]['targetDPI'])) {

        foreach ($derivativeTypes[$derivativeType]['targetDPI'] as $key => $value) {

            if ($original['dpis'] > $value['higher'] && $original['dpis'] <= $value['lower']) {

                if ($value['target'] == 'half') {
                    $targetDPIs = (int)round($original['dpis'] / 2);
                }

                if ($value['target'] == 'equal') {
                    $targetDPIs = $original['dpis'];
                }

                if (is_int($value['target'])) {
                    $targetDPIs = $value['target'];
                }
            }
        }


        if ($targetDPIs != 0) {
            $targetWidth = round($targetDPIs * $original['px']['width'] / $original['dpis']);
            $targetHeight = round($targetDPIs * $original['px']['height'] / $original['dpis']);
        }

    }


    //CHECK MAXIMUM WIDTH
    if (isset($derivativeTypes[$derivativeType]['maxWidth'])) {
        if ($targetWidth > $derivativeTypes[$derivativeType]['maxWidth']) {
            $targetDPIs = floor($derivativeTypes[$derivativeType]['maxWidth'] * $original['dpis'] / $original['px']['width']);

            $targetWidth = round($targetDPIs * $original['px']['width'] / $original['dpis']);
            $targetHeight = round($targetDPIs * $original['px']['height'] / $original['dpis']);
        }
    }


    //CHECK MAXIMUM HEIGHT
    if (isset($derivativeTypes[$derivativeType]['maxHeight'])) {
        if ($targetHeight > $derivativeTypes[$derivativeType]['maxHeight']) {
            $targetDPIs = floor($derivativeTypes[$derivativeType]['maxHeight'] * $original['dpis'] / $original['px']['height']);

            $targetWidth = round($targetDPIs * $original['px']['width'] / $original['dpis']);
            $targetHeight = round($targetDPIs * $original['px']['height'] / $original['dpis']);
        }
    }


    //FORCED VALUES USED FOR GENERATING THUMBS
    if (isset($derivativeTypes[$derivativeType]['forceLength'])) {

        $rs = ($targetWidth > $targetHeight) ? $derivativeTypes[$derivativeType]['forceLength'] . 'x' : 'x' . $derivativeTypes[$derivativeType]['forceLength'];

        $command = " /usr/bin/convert -limit memory 1024 \"" . $input . "\" ";
        $command .= '-thumbnail ' . $rs . ' ';

        if (isset($derivativeTypes[$derivativeType]['quality'])) {
            $command .= "-quality " . $derivativeTypes[$derivativeType]['quality'] . " ";
        }

        $command .= "-density 72 -strip ";
        $command .= "\"" . $output . "." . $derivativeTypes[$derivativeType]['extension'] . "\" ";

    } else {

        $command = " /usr/bin/convert -limit memory 1024 \"" . $input . "\" ";
        $command .= "-compress " . $derivativeTypes[$derivativeType]['encode'] . " ";

        if (isset($derivativeTypes[$derivativeType]['quality'])) {
            $command .= "-quality " . $derivativeTypes[$derivativeType]['quality'] . " ";
        }

        $command .= "-resample " . $targetDPIs . " ";
        $command .= "-density " . $targetDPIs . " ";
        $command .= "\"" . $output . "." . $derivativeTypes[$derivativeType]['extension'] . "\" ";

    }

    print($command);
    exit(0);
}


//GET COMMAND LINE OPTIONS
//i=input file; b=derivative level; o=output file
$options = getopt("i:b:o:");


//CHECK COMMAND LINE OPTIONS

if (isset($options['i'])) {
    if (!file_exists($options['i'])) {
        echo("\nORIGINAL FILE NOT FOUND\n");
        exit(1);
    }
} else {
    echo("\nORIGINAL FILE NOT DEFINED\n");
    exit(1);
}

if (isset($options['b'])) {
    if (!isset($derivativeTypes[$options['b']])) {
        echo("\nUNKNOWN DERIVATIVE TYPE\n");
        exit(1);
    }
} else {
    echo("\nDERIVATIVE TYPE NOT DEFINED\n");
    exit(1);
}

if (!isset($options['o'])) {
    echo("Output file is not set");
    exit(1);
}

// i = inputfile; o = outputfile; b=derivative level
generateDerivative($options['i'], $options['b'], $options['o']);
exit(1);
?>
