#!/bin/bash

# Starts all servers for the current Openstack user

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for server_id in $(openstack server list -c ID -f value) 
do
  echo starting $server_id
  openstack server start $server_id
done

