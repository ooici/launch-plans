#!/home/cc/app-venv/bin/python

import uuid
import time
import json
import sys
from epu.dashiproc.dtrs import DTRSClient
import dashi.bootstrap as bootstrap
from dashi.bootstrap.containers import DotDict

def main():
    f = open("bootconf.json", "r")
    conf_dict = json.load(f)

    CFG = DotDict(conf_dict['epu']["run_config"]["config"])
    CFG.server.amqp.vhost = '/'

    client_topic = "dtrs_client_%s" % uuid.uuid4()

    client_dashi = bootstrap.dashi_connect(client_topic, CFG=CFG)
    print "PDA: sysname: %s" % client_dashi.sysname

    dtrs_client = DTRSClient(dashi=client_dashi)
    for i in range(0, 3):
        try:
            sites = dtrs_client.list_sites()
            print sites
            break
        except Exception, ex:
            print ex
            time.sleep(5);

    # if we passed check one more time to avoid a fluke.  If we failed give
    # a brubbah one more shot at glory
    sites = dtrs_client.list_sites()
    print sites
    return 0

rc = main()
sys.exit(rc)

