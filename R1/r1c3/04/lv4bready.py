#!/usr/bin/env python

APP_DIR="/home/epu4b/app"
VENV_TRIAL=APP_DIR + "/bin/trial"

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
        
run = [VENV_TRIAL, "itv_tests/boot_level_tests/test_bootlevel4.py"]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT, env={"ION_TEST_CASE_SYSNAME":exchange})

if retcode:
    print "Problem running trial test"
sys.exit(retcode)
