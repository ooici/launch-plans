#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-d|--provisioner name]
[-n|--name run]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -p | --provisioner )    shift
                                provisioner=$1
                                ;;
        -n | --name )           shift
                                run_name=$1
                                ;;
        -h | --help )           echo "$USAGE"
                                exit
                                ;;
        * )                     echo "$USAGE"
                                exit 1
    esac
    shift
done

if [ -z "$virtualenv" ]; then
    echo "You must set a virtualenv"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$provisioner" ]; then
    echo "Your provisioner must be set"
    echo $USAGE
    exit $ERROR
fi

ACTIVATE="${virtualenv}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then
    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

status=`$CEICTL --yaml -d $provisioner -n $run_name provisioner terminate_all`
if [ $? -ne 0 ]; then
    exit $ERROR
fi
exit
