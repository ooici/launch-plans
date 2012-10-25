#!/home/epu/app-venv/bin/python

import uuid
import time
import json
import sys
from epu.dashiproc.epumanagement import EPUManagementClient
import dashi.bootstrap as bootstrap
from dashi.bootstrap.containers import DotDict


def main():
    f = open("bootconf.json", "r")
    conf_dict = json.load(f)

    CFG = DotDict(conf_dict['epu']["run_config"]["config"])
    CFG.server.amqp.vhost = '/'

    client_topic = "epum_client_%s" % uuid.uuid4()

    client_dashi = bootstrap.dashi_connect(client_topic, CFG=CFG)
    
    epum_client = EPUManagementClient(client_dashi, topic='epu_management_service')
    for i in range(0, 3):
        try:
            defs = epum_client.list_domain_definitions()    
            print defs
            break
        except Exception, ex:
            print ex
            time.sleep(5);

    # if we passed check one more time to avoid a fluke.  If we failed give 
    # a brubbah one more shot at glory
    defs = epum_client.list_domain_definitions()    
    print defs
    return 0


rc = main()
sys.exit(rc)

