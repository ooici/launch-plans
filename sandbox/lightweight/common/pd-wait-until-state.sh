#!/bin/bash

ERROR=1
DEFAULT_TIMEOUT=60
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-d|--processdispatcher pdname]
[-i|--upid id]
[-s|--state 800-RUNNING|]
[-t|--timeout secs|]
[-n|--name run]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -d | --processdispatcher )       shift
                                processdispatcher=$1
                                ;;
        -i | --upid )           shift
                                upid=$1
                                ;;
        -s | --state )          shift
                                wantstate=$1
                                ;;
        -t | --timeout )        shift
                                timeout=$1
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

if [ -z "$wantstate" ]; then
    echo "Your waiting state must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$timeout" ]; then
    timeout=$DEFAULT_TIMEOUT
fi

if [ -z "$upid" ]; then
    #Try to get id from upid from bootout.json from readypgm
    upid=`cat bootout.json | awk '/upid/ {print $2}' | tr -d '",'`
    if [ -z "$upid" ]; then
        echo "You must provide a upid for the process"
        echo $USAGE
        exit $ERROR
    fi
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

while true ; do
    status=`$CEICTL --yaml -n $run_name process describe $upid | awk '/^state: / {print $2}'`
    if [ $? -ne 0 ]; then
        exit $ERROR
    elif [ "$status" = $wantstate ]; then
        break
    elif [ "$status" = "850-FAILED" ]; then
        echo "Service $upid is in a failed state."
        exit $ERROR
    elif [ $timeout -le 0 ]; then
        echo "Service $upid took too long to reach a $wantstate state"
        exit $ERROR
    fi
    echo "Status of $upid is $status, waiting for $wantstate, waiting for $timeout more seconds"
    let timeout=$timeout-1
    sleep 1
done
exit
