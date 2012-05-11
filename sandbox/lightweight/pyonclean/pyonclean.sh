#!/bin/bash
set +e
. bootenv.sh
set -e

if [ -z "$cleancouchdb" ] || [ "$cleancouchdb" -eq "0" ]; then
    echo "\$CLEANCOUCH not set, skipping clean"
    exit 0
fi

if [ -z "$1" ]; then
    echo "please provide a pyon path as the first arg"
    exit 1
fi
export PYON_PATH=$1

CONFIG=`pwd`/bootconf.json

#do pyon cleanup
cd $PYON_PATH
./bin/pycc -x ion.processes.bootstrap.datastore_loader.DatastoreLoader op=clear -c $CONFIG
