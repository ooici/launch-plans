#!/usr/bin/env python

APP_DIR="/home/cc/app"
VENV_PYTHON="/home/cc/app/bin/mypython"

import os
import subprocess
import sys

runcmd = "sudo %s ion/core/data/cassandra_schema_script.py" % VENV_PYTHON
print "Running: %s" % runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT)

if retcode: print >>sys.stderr, "Problem loading Cassandra"
sys.exit(retcode)
