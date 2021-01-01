#!/bin/bash

# Creates all packages

source $HOME/test-osm.rc

# This defines the array "packages"
source package_list.sh

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESCRIPTORS_DIR=$HOME/osm-packages

for descriptor in ${packages[@]}
do
  if [ -d $descriptor_dir ]; then
    osm vnfpkg-create $DESCRIPTORS_DIR/${descriptor}_vnf
    osm nspkg-create $DESCRIPTORS_DIR/${descriptor}_ns
  fi
done

