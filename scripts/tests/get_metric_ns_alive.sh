#!/bin/bash

# Returns 0 if the ns is found alive in prometheus

NS_NAME=$1

if [ -z "$NS_NAME" ]
then
	echo "Missing ns name";
	exit;
fi

myurl=http://localhost:9091/api/v1/query?query=osm_vm_status{ns_name=\"$NS_NAME\",vnf_member_index=\"1\"}
vm_alive=$(curl -s -g $myurl | jq .data.result[0].value[1] | tr -d '"')

if [ $vm_alive == "1" ]
then
	exit 0
else
	exit -1
fi
