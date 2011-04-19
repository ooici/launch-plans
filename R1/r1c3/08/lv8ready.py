#!/usr/bin/env python

# We will have to make something that can automically determine a list of EPU
# controllers to wait for in each level.  For now, hardcoding the name here.

CONTROLLER="level8_epu_controller"

APP_DIR="/home/cc/app"
VENV_PYTHON="/home/cc/app-venv/bin/python"

import os
import subprocess
import sys

ooiciconn = os.path.join(APP_DIR, "ooici-conn.properties")
if not os.path.exists(ooiciconn):
    raise Exception("Could not find file: %s" % ooiciconn)

exchange = None
server = None

f = open(ooiciconn, 'r')
for line in f.readlines():
    if line.rfind("=") >= 1:
        (key, value) = line.split("=")
        if key == "exchange":
            exchange = value.strip()
        elif key == "server":
            server = value.strip()
f.close()

if not exchange and not server:
    raise Exception("Could not find all necessary configurations in order to run epu-state-wait")

run = [VENV_PYTHON, "./scripts/epu-state-wait", exchange, server, CONTROLLER]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT)

if retcode:
    print "Problem waiting for EPU controller stable state for '%s'" % CONTROLLER
sys.exit(retcode)
