#!/bin/bash

# Returns 0 if the ns is found alive in prometheus

if [ "$1" == "--help" ] 
then
	echo "usage: get_metric_ns_alive.sh <ns name>"
	echo "Will return 0 if the NS is found alive in prometheus. Requires Prometheus port redirected to localhost:9091"
	exit 0
fi

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
	echo "Alive"
	exit 0
else
	echo "Not found"
	exit -1
fi

