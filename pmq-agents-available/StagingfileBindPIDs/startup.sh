#!/bin/bash
#
# StagingFileBindPIDs/startup.sh
# 
# Declare the PIDs to the PID resolver
#
# Unsure if the resolve URL without qualifiers needs to point to an access copy ?
#

scripts=$scripts
na=$na
pid=$pid
resolveUrl=$resolveUrl
OR_HOME=$OR_HOME
source $scripts/shared/parameters.sh
db=$db
lid=$lid
pidwebserviceKey=$pidwebserviceKey
pidwebserviceEndpoint=$pidwebserviceEndpoint

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

wget -O $OR_HOME/log/FileBindPIDs_$na.log --header="Content-Type: text/xml" \
    --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
    --no-check-certificate $pidwebserviceEndpoint

mongo $db --quiet --eval "db.getCollection('master.files').update( {'metadata.pid':'$pid'}, {\$set:{'metadata.pidtype':'or'}}, true, false )"

exit $?
