#!/bin/bash
. bootenv.sh

ERROR=1
USAGE="usage: $0 start|stop|status"


if [ -z "$1" ]; then
    echo "You must specify whether to start or stop"
    echo $USAGE
    exit $ERROR
fi
ACTION="$1"

VENV="${virtualenv}"
EXCHANGE="${exchange_scope}"

ACTIVATE="${VENV}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

if [ ! `which epu-harness` ]; then
    echo "'epu-harness' isn't in search path. Is your virtualenv set correctly?"
    echo "Your virtualenv is at '${VENV}', and your PATH is : $PATH"
    exit $ERROR
fi

cp bootconf.json bootconf.yml

echo "${ACTION}ing epu-harness"
epu-harness -x $EXCHANGE $ACTION bootconf.yml
if [ $? -ne 0 ]; then
  exit 1
fi

exit
