#!/bin/bash

# Packaged version: cookbooks come from an archive file that is downloaded.
# Set the URL here.

COOKBOOKS_URL="http://..."

# ========================================================================

if [ ! -d /opt ]; then 
  mkdir /opt
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ ! -d /opt/chef ]; then 
  mkdir /opt/chef
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ ! -d /opt/chef/tmp ]; then 
  mkdir /opt/chef/tmp 
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

mv bootconf.json /opt/chef/chefroles.json
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

mv chefconf.rb /opt/chef/chefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> rerun-chef.sh << "EOF"
#!/bin/bash
CHEFLEVEL="info"
if [ "X" != "X$1" ]; then
  CHEFLEVEL=$1
fi
chef-solo -l $CHEFLEVEL -c /opt/dt-data/run/chefconf.rb -j /opt/dt-data/run/chefroles.json
exit $?
EOF

chmod +x rerun-chef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

mv rerun-chef.sh /opt/rerun-chef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"
/opt/rerun-chef.sh #debug
if [ $? -ne 0 ]; then
  exit 1
fi

