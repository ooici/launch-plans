#!/usr/bin/env python

# We will have to make something that can automically determine a list of EPU
# controllers to wait for in each level.  For now, hardcoding the name here.

CONTROLLER="dataservices_epu_controller"

APP_DIR="/home/epu4/app"
MSG_CONF = APP_DIR + "/messaging.conf"

VENV_PYTHON="/home/epu4/app/bin/python"
VENV_TRIAL="/home/epu4/app/bin/trial"

import os
import subprocess
import sys

run = [VENV_PYTHON, "./scripts/epu-state-wait", MSG_CONF, CONTROLLER]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT)

if retcode:
    print "Problem waiting for EPU controller stable state for '%s'" % CONTROLLER
sys.exit(retcode)
