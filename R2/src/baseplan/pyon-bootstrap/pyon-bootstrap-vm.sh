#!/bin/bash
set +e
. bootenv.sh
set -e

if [ -n "$1" ]; then
    PYON_PATH=$1
else
    echo "Usage: $0 /path/to/pyon"
    exit 1
fi

CONFIG=`pwd`/bootconf.json

cp bootconf.json $PYON_PATH/res/config/pyon.local.yml

cd $PYON_PATH
./bin/store_interfaces -fc --sysname=$sysname
