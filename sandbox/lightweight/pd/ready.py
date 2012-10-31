#!/home/epu/app-venv/bin/python

import uuid
import time
import json
import sys
from epu.dashiproc.processdispatcher import ProcessDispatcherClient
import dashi.bootstrap as bootstrap
from dashi.bootstrap.containers import DotDict


def main():
    f = open("bootconf.json", "r")
    conf_dict = json.load(f)

    CFG = DotDict(conf_dict['pyon']["configure_config"]["config"])
    CFG.server.amqp.vhost = '/'
    CFG.server.amqp.exchange = conf_dict['pyon']['run_config']['config']['processdispatcher']['dashi_exchange']

    client_topic = "pd_client_%s" % uuid.uuid4()

    client_dashi = bootstrap.dashi_connect(client_topic, CFG=CFG)

    sysname = CFG.system.name
    # SUCKS. copied from hardcode in PD.
    pd_name = "%s.dashi_process_dispatcher" % sysname

    pd_client = ProcessDispatcherClient(client_dashi, topic=pd_name)
    for i in range(0, 3):
        try:
            pd_client.describe_processes()
            break
        except Exception, ex:
            print ex
            time.sleep(3);

    # if we passed check one more time to avoid a fluke.  If we failed give
    # a brubbah one more shot at glory
    pd_client.describe_processes()
    return 0


rc = main()
sys.exit(rc)

