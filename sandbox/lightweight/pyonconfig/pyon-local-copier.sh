#!/bin/bash

if [ -z "$1" ]; then
    echo "No pyon config path, skipping writing file"
    exit 0
fi

PYON_CONFIG_LOCATION=$1

cp bootconf.json $PYON_CONFIG_LOCATION
exit $?
