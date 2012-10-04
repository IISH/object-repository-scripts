#!/bin/bash
#
# /shared/siteusage.sh
#
# Adds the GeoIP country code to the collection siteusage
#

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db


# Prepare a list of all records without geo code
# returns _id and IP
for i in {0..10000} # Do not overdo it... 10000 views
do
    doc=$(mongo $db --quiet --eval "var doc=db.siteusage.findOne( {c:{\$exists:false}} ); if ( doc ) { print(doc._id + doc.ip) } else {print('')}")
    if [ "$doc" == "" ] ; then
        exit 0
    fi

    id=${doc:0:24} # An ObjectId has a length of 24 positions
    ip=${doc:24}
    r=$(geoiplookup $ip)
    c=${r:23:2}

    # Cut to "GeoIP Country Edition: NL". A value of 'IP' would mean unknown.
    u="db.siteusage.update({ _id : ObjectId('$id') }, {\$set:{c:'$c'}}, true, false )"
    echo "Update for $u"
    mongo $db --eval "$u"

done