#!/bin/bash
set -e
cd /home/cc/app
ant -lib ivy.jar eoi-integration-test
