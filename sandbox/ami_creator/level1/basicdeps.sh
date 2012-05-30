#!/bin/bash

set -e

# Install dependencies
export DEBIAN_FRONTEND="noninteractive"
sudo -E apt-get update
sudo -E apt-get -q -y install git libevent-dev libncurses-dev \
libsqlite3-dev libyaml-dev libzmq-dev python-dev python-pip python-pysqlite2 \
python-setuptools python-virtualenv rabbitmq-server swig ruby ruby-dev \
libopenssl-ruby rdoc ri irb build-essential wget ssl-cert curl >/dev/null 2>&1 < /dev/null

# Install RubyGems
cd /tmp
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.tgz
tar zxf rubygems-1.8.24.tgz
cd rubygems-1.8.24
sudo ruby setup.rb --no-format-executable

# Install Chef
sudo gem install chef --no-ri --no-rdoc

# Clone dt-data to get /opt/dt-data/bin/vm-bootstrap
# Use the default master branch
cd /opt
sudo git clone git://github.com/ooici/dt-data.git

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

# Increase open file descriptor limits
sudo sh -c "echo 'fs.file-max = 131072' >> /etc/sysctl.conf"
sudo sh -c "echo 'rabbitmq        soft    nofile          65536
rabbitmq        hard    nofile          131072
root            soft    nofile          65536
root            hard    nofile          131072' >> /etc/security/limits.conf"
sudo sh -c "echo 'session required        pam_limits.so' >> /etc/pam.d/common-session"

exit 0
