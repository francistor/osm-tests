#!/bin/bash

# Invoke a day 2 operation and wait for the result
# The action is executed in the vnf_index 1 and the name of the operation is "touch"

NS=$1
TIMEOUT_SECONDS=100

token=$(curl --insecure -H "Content-Type: application/yaml" -H "Accept: application/yaml" -X POST --data '{username: "test-user", password: "test", project_id: "test-project"}' https://localhost:9999/osm/admin/v1/tokens 2>/dev/null|awk '($1=="id:"){print $2}')

echo $token

# Find the Network Service (yq r – reads from standard input)

ns_id=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://localhost:9999/osm/nslcm/v1/ns_instances?name=$NS|yq r - [0]._id)
echo $ns_id

# Execute the command

operation_id=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/json" -X POST  https://localhost:9999/osm/nslcm/v1/ns_instances/${ns_id}/action -d '{member_vnf_index: "1", primitive: "touch", primitive_params:{filename: "/tmp/day2-scripted"}}' | jq .id | tr -d '"')
echo $operation_id

# 10 seconds to wait at most
for ((n=0;n<$TIMEOUT_SECONDS;n++))
do
  status=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/json" -X GET  https://localhost:9999/osm/nslcm/v1/ns_lcm_op_occs/$operation_id | jq .operationState | tr -d '"')
  if [ "$status" == "COMPLETED" ]
  then
    echo "[OK]"
    exit 0;
  else
    if [ "$status" == "PROCESSING" ]
    then
      sleep 1;
    else
      echo "[FAILED] $status"
      exit -1;
    fi
  fi
done

echo "[FAILED] Not completed in due time"
exit -1;
