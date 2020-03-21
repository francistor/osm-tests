#!/bin/bash

# Get the authorization token iots_get_token OSM_USER OSM_PASSWORD OSM_PROJECT
export token=$(curl --insecure -H "Content-Type: application/yaml" -H "Accept: application/yaml" -X POST --data "{username: $OSM_USER, password: $OSM_PASSWORD, project_id: $OSM_PROJECT}" https://localhost:9999/osm/admin/v1/tokens 2>/dev/null|awk '($1=="id:"){print $2}')

echo $token
