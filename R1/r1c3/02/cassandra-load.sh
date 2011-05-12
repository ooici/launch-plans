#!/bin/bash

GIT_URL="https://github.com/ooici/dt-data.git"
GIT_BRANCH="master"
CHEF_LOGLEVEL="info"

# ========================================================================

CMDPREFIX=""
if [ `id -u` -ne 0 ]; then
  CMDPREFIX="sudo "
fi

if [ ! -d /opt ]; then 
  $CMDPREFIX mkdir /opt
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ -d /opt/dt-data ]; then
  (cd /opt/dt-data && $CMDPREFIX git fetch)
  if [ $? -ne 0 ]; then
      exit 1
  fi
else
  (cd /opt && $CMDPREFIX git clone $GIT_URL )
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

(cd /opt/dt-data && $CMDPREFIX git checkout $GIT_BRANCH )
if [ $? -ne 0 ]; then
  exit 1
fi

(cd /opt/dt-data && $CMDPREFIX git pull )
if [ $? -ne 0 ]; then
  exit 1
fi


echo "Retrieved the dt-data repository, HEAD is currently:"
(cd /opt/dt-data && $CMDPREFIX git rev-parse HEAD)
echo ""

$CMDPREFIX mkdir -p /opt/dt-data/run
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX mv bootconf.json /opt/dt-data/run/cassloadchefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> chefconf.rb << "EOF"
cookbook_path "/opt/dt-data/cookbooks"
log_level :info
file_store_path "/opt/dt-data/tmp"
file_cache_path "/opt/dt-data/tmp"
Chef::Log::Formatter.show_time = false

EOF

$CMDPREFIX mv chefconf.rb /opt/dt-data/run/cassloadchefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> rerun-cassloadchef.sh << "EOF"
#!/bin/bash
CHEFLEVEL="info"
if [ "X" != "X$1" ]; then
  CHEFLEVEL=$1
fi
rm -rf /home/cassload/app
rm -rf /home/cassload/app-venv
chef-solo -l $CHEFLEVEL -c /opt/dt-data/run/cassloadchefconf.rb -j /opt/dt-data/run/cassloadchefroles.json
exit $?
EOF

chmod +x rerun-cassloadchef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX mv rerun-cassloadchef.sh /opt/rerun-cassloadchef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"
$CMDPREFIX /opt/rerun-cassloadchef.sh  #debug
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running cassandra load"

cd /home/cassload/app
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX /home/cassload/app/bin/python /opt/cache/eggs/ioncore-0.4.13-py2.5.egg/ion/core/data/cassandra_schema_script.py

if [ $? -ne 0 ]; then
  exit 1
fi
