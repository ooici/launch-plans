#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-n|--name run]
[-c|--config cfg.yml]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -n | --name )           shift
                                run_name=$1
                                ;;
        -c | --config )         shift
                                config=$1
                                ;;
        -d | --dt )             shift
                                dt=$1
                                ;;
        -s | --site )           shift
                                site=$1
                                ;; 
        -a | --allocation )     shift
                                allocation=$1
                                ;; 
        -h | --help )           echo "$USAGE"
                                exit
                                ;;
        * )                     echo "$USAGE"
                                exit 1
    esac
    shift
done

#set +e
#. bootenv.sh 2>/dev/null
#set -e


if [ -z "$virtualenv" ]; then
    echo "You must set a virtualenv"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$run_name" ]; then
    echo "You must set a cloudinitd run"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$config" ]; then
    echo "Your configuration must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$dt" ]; then
    echo "Your dt must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$site" ]; then
    echo "Your site must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$allocation" ]; then
    echo "Your allocation must be set"
    echo $USAGE
    exit $ERROR
fi
CONFIG="`pwd`/$config"

# Move to script dir
cd `dirname $0`

ACTIVATE="${virtualenv}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

# TODO: THis script schould be moved to a py entry point
CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then

    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

$CEICTL -n $run_name provisioner provision $dt $site $allocation $CONFIG

exit
