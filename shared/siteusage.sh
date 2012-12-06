#!/bin/bash
#
# /shared/siteusage.sh -na [na]
#
# Adds the GeoIP country code to the collection siteusage
#

scripts=$scripts
db=$db


# Prepare a list of all records without geo code
# returns _id and IP
for i in {0..1000} # Do not overdo it... 1000 views
do
    ip=$(mongo localhost:27018/$db --quiet --eval "var doc=db.siteusage.findOne( {c:{\$exists:false}} ); if ( doc ) { print(doc.ip) } else {print('')}")
    if [ "$ip" == "" ] ; then
        break
    fi

    r=$(geoiplookup $ip)
    c=${r:23:2}

    # Cut to "GeoIP Country Edition: NL". A value of 'IP' would mean unknown.
    u="db.siteusage.update( {\$and: [ { ip : '$ip' }, {c:{\$exists:false}} ]}, {\$set:{c:'$c'}}, true, true )"
    echo "Update for $u"
    mongo localhost:27018/$db --eval "$u"

done