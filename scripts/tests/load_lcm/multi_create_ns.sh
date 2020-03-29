#!/bin/bash

# Creates a specific ns a given number of times (1 by default)

if [ "$1" == "--help" ] 
then
	echo "usage: multi_create_ns.sh <ns name> <number of iterations>"
	echo "Creates the ns the specified number of times"
	exit 0
fi


source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NSD=$1
TIMES=${2:-1}

vim_id=$(osm vim-list | grep devstack-vim | cut -d "|" -f 3|xargs)

for ((n=0;n<$TIMES;n++))
do
  random=$(date +%s%N);
  ns_name=${NSD}_$random;
  osm ns-create --wait --nsd_name $NSD --ns_name $ns_name --ssh_keys $HOME/my-keypair.public --vim_account $vim_id
  status=$(osm ns-list | grep $ns_name | cut -d "|" -f 5 | xargs)
  if [ "$status" != "READY" ]
  then
          echo "[FAILED] Error instantiating $ns_name"
	  exit -1
  else
	  echo "[OK] $n created $ns_name"
  fi

  echo

done
