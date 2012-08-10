#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-p|--process-dispatcher pdname]
[-t|--pddir pddirectory]
[-n|--name run]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )         shift
                                    virtualenv=$1
                                    ;;
        -p | --process-dispatcher ) shift
                                    pd=$1
                                    ;;
        -t | --pddir )              shift
                                    pddir=$1
                                    ;;
        -n | --name )               shift
                                    run_name=$1
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


if [ -z "$pd" ]; then
    dtrs="process-dispatcher"
fi

if [ -z "$pddir" ]; then
    pddir="process-definitions"
fi

if [ -z "$run_name" ]; then
    echo "You must set a cloudinitd run"
    echo $USAGE
    exit $ERROR
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
for pd_file in `ls $pddir/*.yml`; do
    pd_name=`basename $pd_file | sed 's/.yml//'`
    $CEICTL --yaml --pyon -n $run_name process-definition create -i $pd_name $pd_file
done

exit
