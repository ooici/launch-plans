#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-d|--process-dispatcher pdname]
[-n|--name run]
[-b|--host brokerhostname]
[-u|--username username]
[-p|--password password]
[-x|--exchange exchange]
[-s|--sysname sysname]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -n | --name )               shift
                                    run_name=$1
                                    ;;
        -b | --host )               shift
                                    host=$1
                                    ;;
        -u | --username )           shift
                                    username=$1
                                    ;;
        -p | --password )           shift
                                    password=$1
                                    ;;
        -s | --sysname )            shift
                                    sysname=$1
                                    ;;
        -x | --exchange )           shift
                                    exchange=$1
                                    ;;
        -d | --process-dispatcher )  shift
                                    process_dispatcher=$1
                                    ;;
        -h | --help )               echo "$USAGE"
                                    exit
                                    ;;
        * )                         echo "$USAGE"
                                    exit 1
    esac
    shift
done

if [ -z "$process_dispatcher" ]; then
    process_dispatcher="process_dispatcher"
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

# Move to script dir
cd `dirname $0`

CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then

    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

# Disable system boot mode
exec $CEICTL $CEICTL_ARGS -d $process_dispatcher --yaml system-boot off
