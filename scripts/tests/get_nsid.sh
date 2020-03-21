#!/bin/bash

# Get the network service id
export ns_id=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://localhost:9999/osm/nslcm/v1/ns_instances?name=$1|yq -r .[0]._id)

echo $ns_id
