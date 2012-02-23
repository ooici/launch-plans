#!/bin/sh
# ignore errors when sourceing bootenv.sh
set +e
. bootenv.sh
set -e

echo "It works!"
echo "Pyon path is $pyon_path" 

exit 0
