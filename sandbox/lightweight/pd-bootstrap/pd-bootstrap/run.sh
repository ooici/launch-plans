#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-p|--process-dispatcher pdname]
[-t|--pddir pddirectory]
[-n|--name run]
[-b|--host brokerhostname]
[-u|--username username]
[-p|--password password]
"
echo "args: $@"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )         shift
                                    virtualenv=$1
                                    ;;
        -t | --pddir )              shift
                                    pddir=$1
                                    ;;
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
        -h | --help )               echo "$USAGE"
                                    exit
                                    ;;
        * )                         echo "$USAGE"
                                    exit 1
    esac
    shift
done


set +e
. bootenv.sh 2>/dev/null
set -e

if [ -z "$pddir" ]; then
    pddir="process-definitions"
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

# Add all pds
set +e
for pd_file in `ls $pddir/*.yml`; do
    pd_name=`basename $pd_file | sed 's/.yml//'`
    attempts=5
    for i in $(seq 0 $attempts) ; do
        echo $CEICTL $CEICTL_ARGS --yaml --pyon process-definition create -i $pd_name $pd_file
        $CEICTL $CEICTL_ARGS --yaml --pyon process-definition create -i $pd_name $pd_file
        CEI_RET=$?
        echo "Got $CEI_RET when creating $pd_name"
        if [ $CEI_RET -eq 0 ]; then
            break 1
        fi
        sleep 1
        echo "Retrying ${pd_name}..."
    done
done

exit
