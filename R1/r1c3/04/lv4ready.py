#!/usr/bin/env python

# We will have to make something that can automically determine a list of EPU
# controllers to wait for in each level.  For now, hardcoding the name here.

CONTROLLER="dataservices_epu_controller"

APP_DIR="/home/epu1/app"
MSG_CONF = APP_DIR + "/messaging.conf"

VENV_PYTHON="/home/epu1/app-venv/bin/python"
VENV_TRIAL="/home/epu1/app-venv/bin/trial"

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

run = [VENV_PYTHON, "./scripts/epu-state-wait", MSG_CONF, CONTROLLER]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT)

if retcode:
    print "Problem waiting for EPU controller stable state for '%s'" % CONTROLLER
    sys.exit(retcode)
        

# love this:

readytest = """

import ion.util.ionlog
from twisted.internet import defer
from ion.test.iontest import ItvTestCase
from ion.core import ioninit
from ion.core.process.process import Process
from ion.services.coi.datastore_bootstrap.ion_preload_config import ION_PREDICATES, ION_RESOURCE_TYPES, ION_IDENTITIES
from ion.services.coi.datastore_bootstrap.ion_preload_config import NAME_CFG, CONTENT_ARGS_CFG, PREDICATE_CFG
from ion.services.coi.datastore import ID_CFG

log = ion.util.ionlog.getLogger(__name__)
CONF = ioninit.config(__name__)

class Bootlevel4LocalReadyTest(ItvTestCase):

    app_dependencies = ["res/deploy/bootlevel4.rel"]

    @defer.inlineCallbacks
    def setUp(self):
        yield self._start_container()

    @defer.inlineCallbacks
    def tearDown(self):
        yield self._stop_container()

    @defer.inlineCallbacks
    def test_all_services(self):
        p = Process()
        yield p.spawn()

        for servicename in ['datastore', 'association_service', 'resource_registry_2']:
            (content, headers, msg) = yield p.rpc_send(p.get_scoped_name('system', servicename), 'ping', {})
            # if timeout, will just fail the test

        # perform basic datastore level tests to make sure required things are there
        defaults={}
        defaults.update(ION_RESOURCE_TYPES)
        defaults.update(ION_IDENTITIES)

        for key, value in defaults.items():

            repo_name = value[ID_CFG]

            c_args = value.get(CONTENT_ARGS_CFG)
            if c_args and not c_args.get('filename'):
                break



            result = yield p.workbench.pull('datastore',repo_name)
            self.assertEqual(result.MessageResponseCode, result.ResponseCodes.OK)

            repo = p.workbench.get_repository(repo_name)

            # Check that we got back both branches!
            default_obj = yield repo.checkout(branchname='master')

            self.assertEqual(default_obj.name, value[NAME_CFG])


        for key, value in ION_PREDICATES.items():

            repo_name = value[ID_CFG]

            result = yield p.workbench.pull('datastore',repo_name)
            self.assertEqual(result.MessageResponseCode, result.ResponseCodes.OK)

            repo = p.workbench.get_repository(repo_name)

            # Check that we got back both branches!
            default_obj = yield repo.checkout(branchname='master')

            self.assertEqual(default_obj.word, value[PREDICATE_CFG])
"""

f = open(APP_DIR + "/lv4ready_trial.py", 'w')
f.write(readytest)
f.write("\n")
f.close()

run = [VENV_TRIAL, "lv4ready_trial.py"]
runcmd = ' '.join(run)
print runcmd
retcode = subprocess.call(runcmd, shell=True, cwd=APP_DIR, stderr=subprocess.STDOUT, env={"ION_TEST_CASE_SYSNAME":exchange})

if retcode:
    print "Problem running trial test"
sys.exit(retcode)
