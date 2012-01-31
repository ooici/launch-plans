#!/bin/bash

function procrunning {
    proc=$1
    ps aux | grep $proc | grep -v grep
}

for process in $@; do
    echo "checking $process"
    echo `procrunning $process`
    if [ ! `procrunning $process` ]; then
        exit 1
    fi
done

exit 1
