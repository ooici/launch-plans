#!/bin/sh

if [ -z "$1" ]; then
    echo "please provide a pyon path as the first arg"
    exit 1
fi
export PYON_PATH=$1

CONFIG=`pwd`/bootconf.json 

#do pyon cleanup
cd $PYON_PATH
./bin/pycc --config $CONFIG
