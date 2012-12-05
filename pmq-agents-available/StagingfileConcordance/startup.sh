#!/bin/bash
#
# start.sh
#
# Iterates over all folders and looks for a csv file to validate, create an instruction; and produce mets

mnt=$mnt
scripts=$scripts

for d in $mnt/*
do
    if [ -d $d ] ; then
        for fileSet in $d/*
        do
            if [ -d $fileSet ] ; then
                na=$(basename $fileSet)
                if [ -f $fileSet/validate.txt ] || [ -f $fileSet/valideer.txt ] ; then
                    rm -f $fileSet/vali*
                    $scripts/pmq-agents-available/StagingfileConcordance/validate.sh -na $na -fileSet $fileSet
                fi
                if [ -f $fileSet/ingest.txt ] ; then
                    rm -f $fileSet/ingest.txt
                    $scripts/pmq-agents-available/StagingfileConcordance/ingest.sh -na $na -fileSet $fileSet
                fi
            fi
        done
    fi
done
