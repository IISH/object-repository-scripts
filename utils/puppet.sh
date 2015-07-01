#!/bin/bash

echo "deb http://apt.puppetlabs.com/ precise main
deb-src http://apt.puppetlabs.com/ precise main">/etc/apt/sources.list.d/puppet.list

apt-key adv --recv-key --keyserver pool.sks-keyservers.net 4BD6EC30
apt-get update
apt-get install puppet facter

echo "[main]
server=puppet.socialhistoryservices.org
environment=production
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=/lib/facter

[master]
# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY" > /etc/puppet/puppet.conf


puppet agent --enable
puppet agent -t