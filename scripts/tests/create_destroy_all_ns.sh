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

# This defines the array "packages"
source package_list.sh

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$token" ]; then
  source ../get_token.sh;
fi

vim_id=$(osm vim-list | grep devstack-vim | cut -d "|" -f 3|xargs)

for descriptor in ${packages[@]}
do
    NSD_NAME=${descriptor}_ns
    echo 
    echo "Deploying $NSD_NAME"
    osm ns-create --wait --nsd_name $NSD_NAME --ns_name $NSD_NAME --ssh_keys $HOME/my-keypair.public --vim_account $vim_id
    status=$(osm ns-list |grep $NSD_NAME | cut -d "|" -f 5 | xargs)
    ns_id=$(osm ns-list |grep $NSD_NAME | cut -d "|" -f 3 | xargs)
    if [ "$status" == "READY" ]
    then
	osm ns-delete $NSD_NAME
	sleep 5
	echo "[OK] $NSD_NAME"
    else
	echo "[FAILED] $NSD_NAME"
	exit -1
    fi
done













