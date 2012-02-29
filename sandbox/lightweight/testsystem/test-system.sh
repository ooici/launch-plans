#!/bin/bash
# ignore errors when sourceing bootenv.sh
set +e
. bootenv.sh
set -e

echo "$0 running in `pwd`"
echo "Pyon path is $pyon_path" 

export CEI_LAUNCH_TEST=1
cd $pyon_path
./bin/pycc -x ion.processes.bootstrap.datastore_loader.DatastoreLoader op=dump path=res/dd
./bin/nosetests -a INT,group=sa -v
