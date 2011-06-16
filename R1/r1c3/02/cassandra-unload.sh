#!/bin/bash

CMDPREFIX=""
if [ `id -u` -ne 0 ]; then
  CMDPREFIX="sudo "
fi

echo "Running cassandra load"

cd /home/cassload/app
if [ $? -ne 0 ]; then
  exit 1
fi

$CMDPREFIX /home/cassload/app/bin/cassandra-teardown
if [ $? -ne 0 ]; then
  exit 1
fi