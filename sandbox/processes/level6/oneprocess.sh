#!/bin/bash

HOME="/home/epu"
VENV_ACTIVATE="$HOME/app-venv/bin/activate"
PD="$HOME/pd"

CMDPREFIX=""
if [ `id -u` -ne 0 ]; then
  CMDPREFIX="sudo "
fi

exec $CMDPREFIX $PD/scripts/run_under_env.sh $VENV_ACTIVATE $PD/scripts/epu-process $PD/messaging.yml bootconf.json
