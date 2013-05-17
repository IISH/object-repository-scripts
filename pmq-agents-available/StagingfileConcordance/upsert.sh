#!/bin/bash

objid=$na/$archiveID.$ID
pidwebserviceEndpoint=$pidwebserviceEndpoint
pidwebserviceKey=$pidwebserviceKey
catalog=$catalog
or=$or

soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:UpsertPidRequest> \
                <pid:na>$na</pid:na> \
                <pid:handle> \
                    <pid:pid>$objid</pid:pid> \
                    <pid:locAtt> \
                            <pid:location weight='1' href='$catalog/$archiveID#$ID'/> \
                            <pid:location weight='0' href='$catalog/$archiveID#$ID' view='catalog'/> \
                            <pid:location weight='0' href='$or/mets/$objid' view='mets'/> \
                            <pid:location weight='0' href='$or/pdf/$objid' view='pdf'/> \
                            <pid:location weight='0' href='$or/file/master/$PID' view='master'/> \
                            <pid:location weight='0' href='$or/file/level1/$PID' view='level1'/> \
                            <pid:location weight='0' href='$or/file/level2/$PID' view='level2'/> \
                            <pid:location weight='0' href='$or/file/level3/$PID' view='level3'/> \
                        </pid:locAtt> \
                </pid:handle> \
            </pid:UpsertPidRequest> \
        </soapenv:Body> \
    </soapenv:Envelope>"

file=/tmp/pid.log
echo "Sending $pid"
wget -O $file --header="Content-Type: text/xml" \
    --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
    --no-check-certificate $pidwebserviceEndpoint

pidCheck=$(php $scripts/shared/pid.php -l $file)
rm $file
if [ "${pidCheck}" != "${pid^^}" ] ; then
    echo "ERROR: Pid not returned by webservice"
    exit -1
fi