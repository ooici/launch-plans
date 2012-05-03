#!/bin/bash

HOME="/home/epu"
VENV_ACTIVATE="$HOME/app-venv/bin/activate"
PROVISIONER="$HOME/provisioner"

CMDPREFIX=""
if [ `id -u` -ne 0 ]; then
  CMDPREFIX="sudo "
fi

exec $CMDPREFIX $PROVISIONER/scripts/run_under_env.sh $VENV_ACTIVATE $PROVISIONER/scripts/epu-killer $PROVISIONER/messaging.yml
