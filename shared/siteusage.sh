#!/bin/bash
#
# /shared/siteusage.sh -na [na]
#
# Adds the GeoIP country code to the collection siteusage
#

scripts=$scripts
db=$1


# Prepare a list of all records without geo code
# returns _id and IP
while [ true ] ;
do
    ip=$(mongo $db --quiet --eval "var doc=db.siteusage.findOne( {c:'??'} ); if ( doc ) { print(doc.ip) } else {print('')}")
    if [ -z "$ip" ] ; then
        echo "All ips are accounted for: $ip";
        break
    fi

    r=$(geoiplookup $ip)
    c=${r:23:2}

    # Cut to "GeoIP Country Edition: NL". A value of 'IP' would mean unknown.
    mongo $db --eval "db.siteusage.update( {c:'??', ip : '$ip' }, {\$set:{c:'$c'}}, true, true );printjson(db.runCommand({getlasterror: 1, w: 'majority'}))"
done

mongo $db $scripts/shared/siteusage.js
