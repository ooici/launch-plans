#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-m|--bootmode initial|restart]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -m | --bootmode )       shift
                                bootmode=$1
                                ;;
        -h | --help )           echo "$USAGE"
                                exit
                                ;;
        * )                     echo "$USAGE"
                                exit 1
    esac
    shift
done

if [ -n "$virtualenv" ]; then
    ACTIVATE="${virtualenv}/bin/activate"

    if [ ! -f "$ACTIVATE" ]; then
        echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
        exit $ERROR
    fi

    source $ACTIVATE
fi

# if initial bootmode, clean out ZK first
if [ -n "$bootmode" ]; then
    if [ "$bootmode" == "initial" ]; then
        clean="--clean"
    else
        clean=""
    fi
fi

exec epu-zktool --config bootconf.json setup $clean