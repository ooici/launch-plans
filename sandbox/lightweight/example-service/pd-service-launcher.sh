#!/bin/bash

ERROR=1
USAGE="usage: $0 path/to/virtualenv config.yml"

if [ -z "$1" ]; then
    echo "Your virtualenv must be the first argument"
    echo $USAGE
    exit $ERROR
fi
VENV="$1"

if [ -z "$2" ]; then
    echo "Your configuration must be the second argument"
    echo $USAGE
    exit $ERROR
fi
CONFIG="`pwd`/$2"


ACTIVATE="${VENV}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

# TODO: THis script schould be moved to a py entry point
EPU_PROCESS="epu-process"
if [ ! `which $EPU_PROCESS` ]; then

    EPU_PROCESS_ABS="${VENV}/epu/scripts/${EPU_PROCESS}"
    if [ -x "$EPU_PROCESS_ABS" ]; then
        EPU_PROCESS=$EPU_PROCESS_ABS
    else
        echo "'epu-harness' isn't in search path. Is your virtualenv set correctly?"
        exit $ERROR
    fi
fi


$EPU_PROCESS $CONFIG $CONFIG pd_0
if [ $? -ne 0 ]; then
  exit 1
fi

exit
