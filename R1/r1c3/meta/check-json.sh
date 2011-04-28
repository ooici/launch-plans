#!/bin/bash

# Run from main directory: ./meta/check-json.sh

for f in `find . -iname "*json"`; do 
  echo "------ $f ------"
  python -m json.tool $f
  if [ $? -ne 0 ]; then
    exit 1
  fi
done
