#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-a|--action stop|start]
[-i|--upid id]
[-d|--processdispatcher pdname]
[-c|--config cfg.yml]
[-n|--name run]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -a | --action )         shift
                                action=$1
                                ;;
        -d | --processdispatcher )       shift
                                processdispatcher=$1
                                ;;
        -i | --upid )           shift
                                upid=$1
                                ;;
        -c | --config )         shift
                                config=$1
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

if [ -z "$processdispatcher" ]; then
    echo "Your process dispatcher must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$config" ]; then
    echo "Your configuration must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$action" ]; then
    echo "Your action must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$run_name" ]; then
    echo "You must set a cloudinitd run"
    echo $USAGE
    exit $ERROR
fi

CONFIG="`pwd`/$config"


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

if [ "$action" = "start" ]; then
    bootout=`$CEICTL --json -n $run_name process dispatch $CONFIG`
    echo "$bootout" > bootout.json
    if [ $? -ne 0 ]; then
        exit 1
    fi

elif [ "$action" = "stop" ]; then

    if [ -z "$upid" ]; then
        #Try to get id from upid from bootout.json from readypgm
        upid=`cat bootout.json | awk '/upid/ {print $2}' | tr -d '",'`
        if [ -z "$upid" ]; then
            echo "You must provide a upid for the process"
            echo $USAGE
            exit $ERROR
        fi
    fi

    $CEICTL --json -n $run_name process kill $upid
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Delete Config file
    rm $CONFIG
fi

exit
