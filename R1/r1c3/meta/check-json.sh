#!/bin/bash

# Run from main directory: ./meta/check-json.sh

for f in `find . -iname "*json"`; do 
  python -m json.tool $f
done
