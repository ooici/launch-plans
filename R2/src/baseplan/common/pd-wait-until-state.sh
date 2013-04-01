#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-d|--processdispatcher pdname]
[-i|--upid id]
[-n|--name run]
[-H|--haagent name]
[-b|--host brokerhostname]
[-u|--username username]
[-p|--password password]
[-s|--sysname sysname]
[-x|--exchange xchg]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
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
        -n | --name )           shift
                                run_name=$1
                                ;;
        -s | --sysname )        shift
                                sysname=$1
                                ;;
        -H | --haagent )        shift
                                haagent=$1
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
        if [ -n "$sysname" ]; then
            CEICTL_ARGS="$CEICTL_ARGS -s $sysname"
        fi
    fi
fi

# add dashi timeout
CEICTL_ARGS="${CEICTL_ARGS} -t 15"

if [ -z "$upid" ]; then
    #Try to get id from upid from bootout.json from readypgm
    upid=`cat bootout.json | awk '/upid/ {print $2}' | tr -d '",'`
    if [ -z "$upid" ]; then
        echo "You must provide a upid for the process"
        echo $USAGE
        exit $ERROR
    fi
fi


CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then
    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

echo $CEICTL $CEICTL_ARGS -d $processdispatcher process wait $upid
$CEICTL $CEICTL_ARGS -d $processdispatcher process wait $upid
if [ $? -ne 0 ]; then
    exit $ERROR
fi

# also query HA Agent and wait for READY/STEADY state
echo "process OK. polling HA"

if [ -n "$haagent" ]; then
    $CEICTL $CEICTL_ARGS ha wait $haagent
    if [ $? -ne 0 ]; then
        exit $ERROR
    fi
fi

echo "HA ok!"
