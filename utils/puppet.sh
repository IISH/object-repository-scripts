#!/bin/bash

echo "deb http://apt.puppetlabs.com/ precise main
deb-src http://apt.puppetlabs.com/ precise main">/etc/apt/sources.list.d/puppet.list

wget -O /tmp/pubkey.gpg http://apt.puppetlabs.com/pubkey.gpg
gpg --import /tmp/pubkey.gpg
gpg -a --export 4BD6EC30 | apt-key add -
apt-get update
apt-get install facter puppet-common=3.8.3-1puppetlabs1
apt-mark hold puppet-common

echo "[main]
environment=production
factpath=/lib/facter
logdir=/var/log/puppet
rundir=/var/run/puppet
ssldir=/var/lib/puppet/ssl
vardir=/var/lib/puppet

[agent]
allow_duplicate_certs=true
masterport=443
report=false
server=puppetmaster.socialhistoryservices.org


[master]
# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY" > /etc/puppet/puppet.conf


puppet agent --enable
rm -rf /var/lib/puppet/ssl
puppet agent -t --waitforcert 10
puppet resource service puppet ensure=running enable=true