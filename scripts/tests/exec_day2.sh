#!/bin/bash

# Invoke a day 2 operation and wait for the result
# The action is executed in the vnf_index 1 and the name of the operation is "touch"

NS=$1
COMMAND=$2

token=$(curl --insecure -H "Content-Type: application/yaml" -H "Accept: application/yaml" -X POST --data '{username: "test-user", password: "test", project_id: "test-project"}' https://localhost:9999/osm/admin/v1/tokens 2>/dev/null|awk '($1=="id:"){print $2}')

# Find the Network Service (yq r – reads from standard input)

ns_id=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://localhost:9999/osm/nslcm/v1/ns_instances?name=$NS|yq r - [0]._id)

# Execute the command

operation_id=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X POST  https://localhost:9999/osm/nslcm/v1/ns_instances/${ns_id}/action -d '{member_vnf_index: "1", primitive: "touch", primitive_params:{filename: "/tmp/day2-scripted"}}')

# Get the status of the operation
sleep 2
curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://localhost:9999/osm/nslcm/v1/ns_lcm_op_occs/$operation_id
