#!/bin/bash
# ignore errors when sourceing bootenv.sh
set +e
. bootenv.sh
set -e

ERROR=1
USAGE="usage: $0 start|stop|status"


if [ -z "$1" ]; then
    echo "You must specify whether to start or stop"
    echo $USAGE
    exit $ERROR
fi
ACTION="$1"

# Set up couchdb
if [ -z "$couchdb_username" ]; then
    echo "You must set the \$couchdb_username"
    exit 1
fi
if [ -z "$couchdb_password" ]; then
    echo "You must set the \$couchdb_password"
    exit 1
fi
if [ -z "$couchdb_host" ]; then
    echo "You must set the \$couchdb_host"
    exit 1
fi

if [ "${ACTION}" = "start" ]; then

    echo "Checking to see if $couchdb_username is already an admin"
    curl -X GET ${couchdb_username}:${couchdb_password}@${couchdb_host}:5984/_config/admins/${couchdb_username} | grep -i error
    if [ $? -ne 0 ]; then
      echo "${couchdb_username} is already an admin, no need to create again"
      exit 0
    fi

    echo "Setting couchdb admin user"
    curl -X PUT ${couchdb_host}:5984/_config/admins/${couchdb_username} -d "\"${couchdb_password}\""
    if [ $? -ne 0 ]; then
      echo "Unable to setup couchdb admin user!"
      exit 1
    fi
elif [ "${ACTION}" = "stop" ]; then

    echo "Cleaning up couchdb admin user"
    curl -X DELETE "${couchdb_username}:${couchdb_password}@${couchdb_host}:5984/_config/admins/${couchdb_username}"
    if [ $? -ne 0 ]; then
      echo "Unable to remove couchdb admin user!"
      exit 1
    fi
fi

exit
