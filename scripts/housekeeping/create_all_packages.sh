#!/bin/bash

# Creates all packages

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESCRIPTORS_DIR=$THIS_DIR/../../descriptors
cd $DESCRIPTORS_DIR;

for descriptor_dir in *
do
  if [ -d $descriptor_dir ]; then
    osm vnfpkg-create ${descriptor_dir}/${descriptor_dir}_vnf
    osm nspkg-create ${descriptor_dir}/${descriptor_dir}_ns
  fi
done

