#!/bin/bash

# Creates all packages

source $HOME/test-osm.rc


THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESCRIPTORS_DIR=$HOME/osm-packages

# This one does not follow the naming convention
tar -czf $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_vnf.tar.gz -C $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_vnf .
tar -czf $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_ns.tar.gz -C $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_ns .
osm upload-package $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_vnf.tar.gz
osm upload-package $DESCRIPTORS_DIR/charm-packages/native_k8s_charm_ns.tar.gz

