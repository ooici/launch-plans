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

cd $PYON_PATH
./bin/store_interfaces --config $CONFIG
