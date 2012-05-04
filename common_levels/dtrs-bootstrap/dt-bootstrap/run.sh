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

# Build Site config
if [ -z "$name" ] || [ -z "$description" ] || [ -z "$driver_class" ] ; then
    echo "You need at least a name, description and driver_class for a site definition" >&2
    exit 1
fi
SITE_FILE=`mktemp -t siteXXXXX`
echo "---
name: $name
description: $description
driver_class: $driver_class""" > $SITE_FILE
$CEICTL --yaml -n $run_name site add --definition $SITE_FILE $name
if [ $? -ne 0 ]; then
    echo "Couldn't add site $name ($SITE_FILE)" >&2
    exit 1
fi
rm -f $SITE_FILE


# Build Credentials config
if [ -z "$access_key" ] || [ -z "$secret_key" ] || [ -z "$key_name" ] ; then
    echo "You need at least an access_key, secret_key and key_name for a site definition" >&2
    exit 1
fi
CREDENTIAL_FILE=`mktemp -t credentialXXXX`
echo "---
access_key: $access_key
secret_key: $secret_key
key_name: $key_name" > $CREDENTIAL_FILE
$CEICTL --yaml -c $caller -n $run_name credentials add --definition $CREDENTIAL_FILE $name
if [ $? -ne 0 ]; then
    echo "Couldn't add credential $name ($CREDENTIAL_FILE)" >&2
    exit 1
fi
rm -f $CREDENTIAL_FILE

# Add all dts
for dt_file in `ls $dtdir/*.yml`; do
    dt_name=`basename $dt_file | sed 's/.yml//'`
    $CEICTL --yaml -c $caller -n $run_name dt add --definition $dt_file $dt_name
done

exit
