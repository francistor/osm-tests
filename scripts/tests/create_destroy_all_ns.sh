#!/bin/bash

# Creates and deletes all network services

if [ "$1" == "--help" ] 
then
	echo "usage: create_destroy_all_ns.sh"
	echo "no params"
	echo "Will create one NS per descriptor present in the directory"
	exit 0
fi

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$token" ]; then
  source ../get_token.sh;
fi

vim_id=$(osm vim-list | grep devstack-vim | cut -d "|" -f 3|xargs)

DESCRIPTORS_DIR=$THIS_DIR/../../descriptors
cd $DESCRIPTORS_DIR;

for descriptor_dir in *
do
  if [ -d $descriptor_dir ]; then
    NSD_NAME=${descriptor_dir}_ns
    osm ns-create --wait --nsd_name $NSD_NAME --ns_name $NSD_NAME --ssh_keys $HOME/my-keypair.public --vim_account $vim_id
    status=$(osm ns-list |grep $NSD_NAME | cut -d "|" -f 5 | xargs)
    ns_id=$(osm ns-list |grep $NSD_NAME | cut -d "|" -f 3 | xargs)
    if [ "$status" == "READY" ]
    then
	osm ns-delete $NSD_NAME
	sleep 5
	juju destroy-model -y $ns_id 2> /dev/null
	echo "[OK] $NSD_NAME"
    else
	echo "[FAILED] $NSD_NAME"
	exit -1
    fi
  fi
done













