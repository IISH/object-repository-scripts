#!/bin/bash
#
# hosts must resolve...
#

cd /opt

/opt/object-repository/agent.sh stop
sleep 3

# If the certificates are not placed in the keystore or need to be replaced, then run this script with the
# ./build.sh cacerts
# option
if [ ! -z "$1" ] ; then

    keystore="$1"
    for alias in "bamboo.socialhistoryservices.org" "pid.socialhistoryservices.org"
    do
        cer_file=$alias.cer
        pem_file=$alias.pem
        openssl s_client -connect $alias:443 > $cer_file
        openssl x509 -outform der -in $cer_file -out $pem_file
        keytool -delete -alias $alias -keystore $keystore
        keytool -import -alias $alias -file $pem_file -keystore $keystore
        rm $cer_file
        rm $pem_file
    done
fi

aptitude install ant1.8
cd /opt
rm build.xml
wget --no-check-certificate https://raw.github.com/IISH/object-repository-scripts/master/build.xml
ant

echo "Now do not forget to set the /etc/environment"
