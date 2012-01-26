#!/bin/bash

ERROR=1
USAGE="usage: $0 path/to/virtualenv start|stop"


if [ -z "$1" ]; then
    echo "Your virtualenv must be the first argument"
    echo $USAGE
    exit $ERROR
fi
VENV="$1"

if [ -z "$2" ]; then
    echo "You must specify whether to start or stop"
    echo $USAGE
    exit $ERROR
fi
ACTION="$2"

if [ -z "$3" ]; then
    echo "You must specify an exchange scope as your third argument"
    echo $USAGE
    exit $ERROR
fi
EXCHANGE="$3"

ACTIVATE="${VENV}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

if [ ! `which epu-harness` ]; then
    echo "'epu-harness' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

cp bootconf.json bootconf.yml

echo "${ACTION}ing epu-harness"
epu-harness -x $EXCHANGE $ACTION bootconf.yml
if [ $? -ne 0 ]; then
  exit 1
fi

exit
