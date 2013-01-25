#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-d|--dtrs dtrsname]
[-t|--dtdir dtdirectory]
[-s|--sitedir sitedirectory]
[-u|--caller caller_name]
[-c|--credentials iaas_credentials.yml]
[-n|--name run]
[-z|--sysname sysname]
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
        -s | --sitedir )        shift
                                sitedir=$1
                                ;;
        -c | --credsdir )       shift
                                credsdir=$1
                                ;;
        -u | --caller )         shift
                                caller=$1
                                ;;
        -n | --name )           shift
                                run_name=$1
                                ;;
        -z | --sysname )        shift
                                sysname=$1
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


if [ -z "$dtrs" ]; then
    dtrs="dtrs"
fi

if [ -z "$dtdir" ]; then
    dtdir="dt"
fi

if [ -z "$sitedir" ]; then
    sitedir="sites"
fi

if [ -z "$credsdir" ]; then
    credsdir="credentials"
fi

if [ -z "$credsdir" ]; then
    credsdir="credentials"
fi

if [ -n "$sysname" ]; then
    extras="-s $sysname"
else
    extras=""
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

# TODO: THis script schould be moved to a py entry point
CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then

    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

# Add all sites
for site_file in `ls $sitedir/*.yml`; do
    site_name=`basename $site_file | sed 's/.yml//'`
    $CEICTL --yaml $extras -n $run_name site add --force --definition $site_file $site_name
done

# Add credentials for one site
for creds_file in `ls $credsdir/*.yml`; do
    iaas_site=`basename $creds_file | sed 's/.yml//'`
    $CEICTL --yaml $extras -c $caller -n $run_name credentials add --force --definition $creds_file $iaas_site
    if [ $? -ne 0 ]; then
        echo "Couldn't add credential $iaas_site ($iaas_credentials)" >&2
        exit 1
    fi
done

# Add all dts
for dt_file in `ls $dtdir/*.yml`; do
    dt_name=`basename $dt_file | sed 's/.yml//'`
    $CEICTL --yaml $extras -c $caller -n $run_name dt add --force --definition $dt_file $dt_name
done

exit
