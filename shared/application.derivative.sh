#!/bin/bash
#
# Runs Audio conversion software to convert an audio file into a ( smaller ) version.
# Then ingests the derivative into the correct bucket.
#

scripts=$scripts
contentType=$contentType
derivative=$derivative
if [ "$contentType" == "applcation/pdf" ] ; then
    source $scripts/shared/image.derivative.sh
fi

echo "We cannot make a derivative of type $derivative"
echo "This is not an error. Just there is no such service."
exit 250