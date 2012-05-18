#!/bin/bash

# ========================================================================
# The run name can differentiate multiple chef runs on same base node
# ========================================================================

if [ "X" == "X$1" ]; then
  echo "argument required, the run name"
  exit 1
fi

RUN_NAME=$1

# the archive url can be passed in as an optional second argument
if [ "X$2" == "X" ]; then
    DTDATA_ARCHIVE_URL="http://ooici.net/releases/dt-data-develop.tar.gz"
else
    DTDATA_ARCHIVE_URL=$2
fi

CHEF_LOGLEVEL="info"
DTDATA_DIR="/opt/dt-data"
DTDATA_ARCHIVE_PATH="/opt/dt-data.tar.gz"

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

$CMDPREFIX wget -O $DTDATA_ARCHIVE_PATH $DTDATA_ARCHIVE_URL
if [ $? -ne 0 ]; then
  exit 1
fi

if [ -d $DTDATA_DIR ]; then
  $CMDPREFIX mv $DTDATA_DIR $DTDATA_DIR.`date +%s`
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

$CMDPREFIX mkdir $DTDATA_DIR
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX tar xzf $DTDATA_ARCHIVE_PATH -C $DTDATA_DIR --strip 1
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX mkdir -p /opt/dt-data/run/$RUN_NAME
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX cp bootconf.json /opt/dt-data/run/$RUN_NAME/chefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> chefconf.rb << "EOF"
cookbook_path "/opt/dt-data/cookbooks"
log_level :info
file_store_path "/opt/dt-data/tmp"
file_cache_path "/opt/dt-data/tmp"
Chef::Log::Formatter.show_time = true

EOF

$CMDPREFIX mv chefconf.rb /opt/dt-data/run/$RUN_NAME/chefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> rerun-chef-$RUN_NAME.sh << "EOF"
#!/bin/bash
CHEFLEVEL="info"
if [ "X" != "X$1" ]; then
  CHEFLEVEL=$1
fi
EOF

echo "rm -rf /home/$RUN_NAME/app /home/$RUN_NAME/app-venv" >> rerun-chef-$RUN_NAME.sh
echo "chef-solo -l \$CHEFLEVEL -c /opt/dt-data/run/$RUN_NAME/chefconf.rb -j /opt/dt-data/run/$RUN_NAME/chefroles.json" >> rerun-chef-$RUN_NAME.sh
echo 'exit $?' >> rerun-chef-$RUN_NAME.sh

chmod +x rerun-chef-$RUN_NAME.sh
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX mv rerun-chef-$RUN_NAME.sh /opt/rerun-chef-$RUN_NAME.sh
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"
$CMDPREFIX /opt/rerun-chef-$RUN_NAME.sh  #debug
if [ $? -ne 0 ]; then
  exit 1
fi
