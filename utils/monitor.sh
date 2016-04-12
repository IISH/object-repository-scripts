#!/bin/bash
#
# monitor.sh
#
# Purpose: restart tomcat if a know issue occurs in the log.


if (( $(pgrep -c "monitor.sh") == 1 )) ; then
    echo "Self"
else
    echo "Already running"
    exit 1
fi


file=/var/log/tomcat6/catalina.out
s=/opt/status.log

grep "JAVA-767\|com.mongodb.MongoException\$CursorNotFound" $file
rc=$?
if [[ $rc == 0 ]] ; then
    rm -f $file
    echo "$(date): Invalid response ${rc}" >> $s

    service tomcat6 stop
    sleep 60
    service tomcat6 restart

    exit 1
else
    echo "$(date)">>$s
    exit 0
fi