#!/bin/bash
#
# start.sh
#
# Iterates over all folders and looks for a csv file to validate, create an instruction; and produce mets

mnt=$mnt
scripts=$scripts
mailTo=$(cat $mnt/mail.txt)

for project in $mnt/*
do
    for d in $project/*
    do
        if [ -d $d ] ; then
            na=$(basename $d)
            for fileSet in $d/*
            do
                if [ -d $fileSet ] ; then
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
done