#!/bin/bash
set +e
. bootenv.sh
set -e

if [ -n "$1" ]; then
    PYON_PATH=$1
else
    PYON_PATH="/home/${epu_username}/coi-services/"
fi

CONFIG=`pwd`/bootconf.json

#do pyon cleanup
cd $PYON_PATH
# ./bin/pycc -X system.auto_bootstrap=True --config $CONFIG
./bin/store_interfaces --config $CONFIG
