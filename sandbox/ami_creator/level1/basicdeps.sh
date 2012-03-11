#!/bin/bash

set -e

# Install dependencies
export DEBIAN_FRONTEND="noninteractive"
sudo -E apt-get update
sudo -E apt-get -q -y install chef git libevent-dev libncurses-dev \
libsqlite3-dev libyaml-dev libzmq-dev python-dev python-pip python-pysqlite2 \
python-setuptools python-virtualenv rabbitmq-server swig >/dev/null 2>&1 < /dev/null

# Clone dt-data to get /opt/dt-data/bin/vm-bootstrap
# Use the dashi branch
cd /opt
sudo git clone git://github.com/ooici/dt-data.git
cd dt-data
sudo git checkout -b dashi origin/dashi

# Add the bootstrap script to /etc/rc.local
sudo sh -c 'cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

/opt/dt-data/bin/vm-bootstrap
exit 0
EOF'

# Disable chef-client on boot
sudo update-rc.d chef-client disable

exit 0
