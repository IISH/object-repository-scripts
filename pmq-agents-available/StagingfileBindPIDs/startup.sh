#!/bin/bash
#
# StagingFileBindPIDs/startup.sh
# 
# Declare the PIDs to the PID resolver
#
# Unsure if the resolve URL without qualifiers needs to point to an access copy ?
#

scripts=$scripts
action=$action
na=$na
pid=$pid
resolveUrl=$resolveUrl
identifier=$identifier
source $scripts/shared/parameters.sh
db=$db
lid=$lid
pidwebserviceKey=$pidwebserviceKey
pidwebserviceEndpoint=$pidwebserviceEndpoint


if [ "$action" == "delete" ] ; then
    soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:DeletePidRequest> \
                <pid:pid>$pid</pid:pid> \
            </pid:DeletePidRequest> \
        </soapenv:Body> \
    </soapenv:Envelope>"
else
    soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:UpsertPidRequest> \
                <pid:na>$na</pid:na> \
                <pid:handle> \
                    <pid:pid>$pid</pid:pid> \
                        <pid:locAtt> \
                            <pid:location weight='1' href='$resolveUrl/metadata/$pid'/> \
                            <pid:location weight='0' href='$resolveUrl/file/master/$pid' view='master'/> \
                            <pid:location weight='0' href='$resolveUrl/file/level1/$pid' view='level1'/> \
                            <pid:location weight='0' href='$resolveUrl/file/level2/$pid' view='level2'/> \
                            <pid:location weight='0' href='$resolveUrl/file/level3/$pid' view='level3'/> \
                        </pid:locAtt> \
                    <pid:localIdentifier>$lid</pid:localIdentifier> \
                </pid:handle> \
            </pid:UpsertPidRequest> \
        </soapenv:Body> \
    </soapenv:Envelope>"
fi

file=/tmp/$identifier.log
wget -O $file --header="Content-Type: text/xml" \
    --header="Authorization: bearer $pidwebserviceKey" --post-data "$soapenv" \
    --no-check-certificate $pidwebserviceEndpoint

pidCheck=$(php $scripts/shared/pid.php -l $file)
rm $file
if [ "$action" == "delete" ] ; then
    echo "No check for pid deletion"
    exit 0
else
    if [ "${pidCheck}" != "${pid^^}" ] ; then
        echo "Pid not returned by webservice"
        exit -1
    fi
fi

mongo $db --quiet --eval "db.getCollection('master.files').update( {'metadata.pid':'$pid'}, {\$set:{'metadata.pidType':'or'}}, true, false )"

exit $?
