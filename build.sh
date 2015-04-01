#!/bin/bash
#
# hosts must resolve...
#
jvm=/usr/lib/jvm/java-6-sun
cd /tmp

# If the certificates are not placed in the keystore or need to be replaced, then run this script with the
# ./build.sh cacerts
# option
if [ ! -z "$1" ] ; then

    keystore="$1"
    for alias in "bamboo.socialhistoryservices.org" "pid.socialhistoryservices.org"
    do
        openssl s_client -connect $alias:443 > $alias.cer
        openssl x509 -outform der -in $alias.cer -out $alias.der
        keytool -delete -alias $alias -keystore $keystore
        keytool -import -alias $alias -file $alias.der -keystore $keystore
        rm $alias.cer
        rm $alias.der
    done
fi

aptitude install ant1.8
cd /opt
rm build.xml
wget --no-check-certificate https://raw.github.com/IISH/object-repository-scripts/master/build.xml
ant

echo "Now do not forget to set the /etc/environment"
