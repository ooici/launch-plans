#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-a|--action stop|start]
[-d|--processdispatcher pdname]
[-c|--config cfg.yml]
[-r|--restart ALWAYS|NEVER|ABNORMAL]
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
        -a | --action )         shift
                                action=$1
                                ;;
        -d | --processdispatcher )       shift
                                processdispatcher=$1
                                ;;
        -r | --restart )        shift
                                restart_mode=$1
                                ;;
        -c | --config )         shift
                                config=$1
                                ;;
        -s | --sysname )        shift
                                sysname=$1
                                ;;
        -j | --process-definition-name ) shift
                                process_definition_name=$1
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

if [ -z "$process_definition_name" ]; then
    echo "Your process definition name must be set"
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

        if [ -n "$processdispatcher" ]; then
            CEICTL_ARGS="$CEICTL_ARGS -d $processdispatcher"
        fi
    fi
fi

if [ -z "$restart_mode" ]; then
    restart_mode="NEVER"
fi

# add dashi timeout
CEICTL_ARGS="${CEICTL_ARGS} -t 15"

CONFIG="`pwd`/$config"


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

if [ "$action" = "start" ]; then
    queueing_mode="ALWAYS"

    upid=`$CEICTL $CEICTL_ARGS --json process schedule --definition-name ${process_definition_name} --queueing-mode ${queueing_mode} --restart-mode ${restart_mode} --config bootconf.json`
    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo "{\"upid\": $upid }" > bootout.json


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

    $CEICTL $CEICTL_ARGS --json process kill $upid
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Delete Config file
    rm $CONFIG
fi

exit
