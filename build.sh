#!/bin/bash
#
# hosts must resolve...
# 195.169.88.28     bamboo.socialhistoryservices.org
# 195.169.88.243    pid.socialhistoryservices.org
#
jvm=/usr/lib/jvm/java-6-sun
cd /tmp

# If the certificates are not placed in the keystore, run this script with the ./deploy.sh cacerts option
if [ "$1" == "cacerts" ] ; then

    aliases="bamboo.socialhistoryservices.org" "pid.socialhistoryservices.org"
    for alias in aliases
    do
        openssl s_client -connect $alias:443 > $alias.cer
        openssl x509 -outform der -in $alias.cer -out $alias.der
        keytool -import -alias $alias -file $alias.der -keystore $jvm/jre/lib/security/cacerts
        rm $alias.cer
        rm $alias.der
    done
fi

aptitude install ant1.8
cd /opt
wget https://raw.github.com/IISH/object-repository-scripts/master/build.xml
ant

echo "Now do not forget to set the /etc/environment"