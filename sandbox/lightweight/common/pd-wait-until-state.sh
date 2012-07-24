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
[-b|--host brokerhostname]
[-u|--username username]
[-p|--password password]
[-x|--exchange xchg]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -b | --host )           shift
                                host=$1
                                ;;
        -u | --username )       shift
                                username=$1
                                ;;
        -p | --password )       shift
                                password=$1
                                ;;
        -x | --exchange )       shift
                                exchange=$1
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

if [ -n "$run_name" ]; then
    CEICTL_ARGS="-n $run_name"

else
    if [ -z "$host" -o -z "$username" -o -z "$password" ]; then
        echo "You must set set either a cloudinitd run or a host and credentials"
        echo $USAGE
        exit $ERROR
    else
        CEICTL_ARGS="-b $host -u $username -p $password"
        if [ -n "$exchange" ]; then
            CEICTL_ARGS="$CEICTL_ARGS -x $exchange"
        fi
    fi
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

if [ -n "$virtualenv" ]; then
    ACTIVATE="${virtualenv}/bin/activate"

    if [ ! -f "$ACTIVATE" ]; then
        echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
        exit $ERROR
    fi

    source $ACTIVATE
fi


CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then
    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

while true ; do
    status=`$CEICTL $CEICTL_ARGS --yaml process describe $upid | awk '/^state: / {print $2}'`
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
    sleep 0.5
done
exit
