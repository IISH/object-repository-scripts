#!/bin/bash

f=$1

if [ -f $f ] ; then

        if [[ "$f" == *md5 ]]; then
                # no need to calculate a md5 for an md5
                echo ""
        else
            md5File="$f.md5"
            if [ -f $md5File ] ; then
                length=$(stat -c%s "$md5File")
                if [ $length=0 ] ; then
                    rm $md5File
                fi
            fi

            echo "Calculating md5 for $f"
            group=`stat -c %g $f`
            user=`stat -c %u $f`
            md5sum "$f" > $md5File
            chown $group:$user $md5File
            chmod 664 $md5File
        fi
fi
