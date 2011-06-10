#!/usr/bin/env python

TRIAL_TEST="itv_tests.services.dm.test_ingestion.IntTestIngest"

APP_DIR="/home/ingestiontest/app"

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
    raise Exception("Could not find all necessary configurations in order to run trial tests")
        
envmap = {"ION_TEST_CASE_SYSNAME": exchange}

run = ["./bin/trial", TRIAL_TEST]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, env=envmap, cwd=APP_DIR, stderr=subprocess.STDOUT)

if retcode:
    print "Problem running trial test: %s" % TRIAL_TEST
sys.exit(retcode)
