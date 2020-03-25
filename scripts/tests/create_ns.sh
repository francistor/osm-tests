#!/bin/bash

# Creates an instance of the specified network service

if [ "$1" == "--help" ] 
then
	echo "usage: create_ns.sh <nsd name>"
	echo "Will create one instance of the specified network service descriptor"
	exit 0
fi

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

vim_id=$(osm vim-list | grep devstack-vim | cut -d "|" -f 3|xargs)

osm ns-create --wait --nsd_name $1 --ns_name $1 --ssh_keys $HOME/my-keypair.public --vim_account $vim_id






