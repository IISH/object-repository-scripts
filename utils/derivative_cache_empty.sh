#!/bin/bash


LIMIT=20

count=$(ls -al "${MAGICK_TMPDIR}" | wc -l)
if [[ $count > $LIMIT ]]
then
   rm -f "${MAGICK_TMPDIR}/*"
fi