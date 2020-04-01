#!/bin/bash

# Create a network service and invoke day 2 operations in an inifinite loop

if [ "$1" == "--help" ] 
then
	echo "usage: main.sh"
	echo "The ns created is ubuntu_2vdu_day2_ns"
	echo "The action invoked is 'touch' with param '/tmp/day2-scripted'"
	exit 0
fi

NSD=ubuntu_2vdu_day2_ns

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

random=$(date +%s%N);

# Create the network service
vim_id=$(osm vim-list | grep devstack-vim | cut -d "|" -f 3|xargs)
osm ns-create --wait --nsd_name $NSD --ns_name ${NSD}_$random --ssh_keys $HOME/my-keypair.public --vim_account $vim_id

# Infinite loop invoking day2 operation
while true
do
	$THIS_DIR/../exec_day2.sh ubuntu_2vdu_day2_ns_$random
done






