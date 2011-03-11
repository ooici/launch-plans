#!/bin/bash

# git version: cookbooks come from git
# Set the repository here

GIT_URL="https://github.com/ooici/dt-data.git"
GIT_REF="origin/HEAD"
CHEF_LOGLEVEL="info"

# ========================================================================

if [ ! -d /opt ]; then 
  sudo mkdir /opt
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ -d /opt/dt-data ]; then
  (cd /opt/dt-data && sudo git fetch)
  if [ $? -ne 0 ]; then
      exit 1
  fi
else
  (cd /opt && sudo git clone $GIT_URL )
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

(cd /opt/dt-data && sudo git reset --hard $GIT_REF )
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Retrieved the dt-data repository, HEAD is currently:"
(cd /opt/dt-data && sudo git rev-parse HEAD)
echo ""

sudo mkdir -p /opt/dt-data/run
if [ $? -ne 0 ]; then
  exit 1
fi

sudo mv bootconf.json /opt/dt-data/run/chefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi

if [ -f provisioner/cei_environment ]; then
    sudo mv provisioner/cei_environment /opt/cei_environment
    if [ $? -ne 0 ]; then
      exit 1
    fi
    chmod 400 /opt/cei_environment
    if [ $? -ne 0 ]; then
      exit 1
    fi
fi
    
cat >> chefconf.rb << "EOF"
cookbook_path "/opt/dt-data/cookbooks"
log_level :info
file_store_path "/opt/dt-data/tmp"
file_cache_path "/opt/dt-data/tmp"
Chef::Log::Formatter.show_time = false

EOF

sudo mv chefconf.rb /opt/dt-data/run/chefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"

sudo chef-solo -l info -c /opt/dt-data/run/chefconf.rb -j /opt/dt-data/run/chefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi


