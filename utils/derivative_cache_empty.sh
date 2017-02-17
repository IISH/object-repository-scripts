#!/bin/bash


LIMIT=20

count=$(ls -al "${MAGICK_TMPDIR}" | wc -l)
if [[ $count -gt $LIMIT ]]
then
   echo "Emptying cache ${MAGICK_TMPDIR}"
   rm -f "${MAGICK_TMPDIR}/*"
fi