#!/bin/bash

curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://localhost:9999/osm/nslcm/v1/ns_instances_content/$ns_id | yq -r .nsState
