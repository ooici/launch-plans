#!/bin/bash

ERROR=1
USAGE="usage: $0 [options]

Options:
[-p|--pyon-path path/to/pyon]
[-m|--bootmode initial|restart]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -p | --pyon-path )          shift
                                    pyon_path=$1
                                    ;;
        -m | --bootmode )           shift
                                    bootmode=$1
                                    ;;
        -h | --help )               echo "$USAGE"
                                    exit
                                    ;;
        * )                         echo "$USAGE"
                                    exit 1
    esac
    shift
done

if [ -z "$pyon_path" ]; then
    echo "You must specify a pyon path"
    echo $USAGE
    exit $ERROR
fi

config=`pwd`/bootconf.json

if [ -n "$bootmode" ]; then
    if [ "$bootmode" == "initial" ]; then
        force_clean="-fc"
    else
        force_clean=""
    fi
fi

cp bootconf.json $pyon_path/res/config/pyon.local.yml

cd $pyon_path
su cc -c "./bin/store_interfaces $force_clean"
