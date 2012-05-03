#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-d|--dtrs dtrsname]
[-t|--dtdir dtdirectory]
[-u|--caller caller_name]
[-c|--config cfg.yml]
[-n|--name run]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -d | --dtrs )           shift
                                dtrs=$1
                                ;;
        -t | --dtdir )          shift
                                dtdir=$1
                                ;;
        -c | --config )         shift
                                config=$1
                                ;;
        -u | --caller )         shift
                                caller=$1
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

set +e
. bootenv.sh 2>/dev/null
set -e


if [ -z "$virtualenv" ]; then
    echo "You must set a virtualenv"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$dtrs" ]; then
    dtrs="dtrs"
fi

if [ -z "$dtdir" ]; then
    dtdir="dt"
fi

if [ -z "$config" ]; then
    echo "Your configuration must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$caller" ]; then
    echo "You must supply a caller"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$run_name" ]; then
    echo "You must set a cloudinitd run"
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

$CEICTL --yaml -n $run_name site add --definition $CONFIG $name
$CEICTL --yaml -c $caller -n $run_name credentials add --definition $CONFIG $name

for dt_file in `ls $dtdir/*.yml`; do
    dt_name=`basename $dt_file | sed 's/.yml//'`
    $CEICTL --yaml -c $caller -n $run_name dt add --definition $dt_file $dt_name
done

exit
