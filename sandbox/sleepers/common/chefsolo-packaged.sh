#!/bin/bash

# Packaged version: cookbooks come from an archive file that is downloaded.
# Set the URL here.

COOKBOOKS_URL="http://..."
CHEF_LOGLEVEL="info"

# ========================================================================

if [ ! -d /opt ]; then 
  sudo mkdir /opt
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ ! -d /opt/chef ]; then 
  sudo mkdir /opt/chef
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ ! -d /opt/chef/tmp ]; then 
  sudo mkdir /opt/chef/tmp 
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

sudo mv bootconf.json /opt/chef/chefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> chefconf.rb << "EOF"
log_level :info
cookbooks_path "/opt/chef/cookbooks"
file_store_path "/opt/chef/tmp"
file_cache_path "/opt/chef/tmp"
Chef::Log::Formatter.show_time = false
EOF

sudo mv chefconf.rb /opt/chef/chefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"

sudo chef-solo -l $CHEF_LOGLEVEL -c /opt/chef/chefconf.rb -j /opt/chef/chefroles.json -r $COOKBOOKS_URL
if [ $? -ne 0 ]; then
  exit 1
fi


