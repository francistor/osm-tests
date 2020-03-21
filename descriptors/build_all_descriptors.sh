#!/bin/bash

# Builds all the descriptors in this directory

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for file in *
do
  if [ -d $file ]; then
    $THIS_DIR/build_descriptor.sh $file;
  fi
done
