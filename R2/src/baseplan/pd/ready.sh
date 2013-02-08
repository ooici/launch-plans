#!/bin/bash
set -e

cd /home/cc/coi-services

# this is tortuously awful. we cannot call buildbot's bin/python
# from outside the coi-services directory. It's also not a "real"
# python, so we can't even feed a script in on stdin. It might be
# slightly better to embed this script in coi-services, but at
# least this is self-contained.

cat >pd_ready.py <<END
from interface.services.cei.iprocess_dispatcher_service import ProcessDispatcherServiceClient
from pyon.net.messaging import make_node
from pyon.core import bootstrap
from pyon.public import CFG
from pyon.core.exception import Timeout

if not bootstrap.pyon_initialized:
    bootstrap.bootstrap_pyon()
node, ioloop = make_node()
node.setup_interceptors(CFG.interceptor)
pd_cli = ProcessDispatcherServiceClient(node=node)

for i in range(3):
    try:
        pd_cli.list_processes(timeout=10)
    except (Exception, Timeout), e:
        # raise error on last attempt
        if i == 2:
            raise
END

exec bin/python pd_ready.py
