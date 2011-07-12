#!/usr/bin/env python

# We will have to make something that can automically determine a list of EPU
# controllers to wait for in each level.  For now, hardcoding the name here.

CONTROLLER="epu_controller"

APP_DIR="/home/anfepu/app"

MESSAGING_CONF="/home/ubuntu/messaging.conf"
VENV_PYTHON="sudo /home/anfepu/app-venv/bin/python"

import os
import subprocess
import sys

run = [VENV_PYTHON, "./scripts/epu-state-wait", MESSAGING_CONF, CONTROLLER]
runcmd = ' '.join(run)
print runcmd

exitcode = -1
while exitcode < 0:
    retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT)
    if not retcode:
        exitcode = 0
    elif retcode == 123:
        exitcode = 123
        print "Problem waiting for EPU controller stable state for '%s'" % CONTROLLER
    else:
        print "epu-state-wait exited with %d, running again." % retcode
sys.exit(exitcode)
