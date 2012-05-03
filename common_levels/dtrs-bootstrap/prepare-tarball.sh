#!/bin/bash

# Move to script dir
cd `dirname $0`

DIRNAME="dt-bootstrap"

if [ ! -d "$DIRNAME" ]; then
  echo "error, packaging script cannot orient itself, no dt directory?"
  exit 1
fi

if [ -f $DIRNAME.tar.gz ]; then
  rm $DIRNAME.tar.gz
  echo "Removed old $DIRNAME.tar.gz"
fi

tar czf $DIRNAME.tar.gz $DIRNAME
if [ $? -ne 0 ]; then
  echo "Failed to create $DIRNAME tarball"
  exit 1
fi

echo "Created $DIRNAME.tar.gz"

cd -
