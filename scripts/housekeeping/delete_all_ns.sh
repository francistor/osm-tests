#!/bin/bash

# Deletes all network service descriptors

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$token" ]; then
  source ../get_token.sh;
fi

nss=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET https://${OSM_HOSTNAME}:${OSM_PORT}/osm/nslcm/v1/ns_instances | yq r - .id)

for ns in $nss
do
  osm ns-delete $ns
done

sleep 5
echo "Checking for juju orphan models"
echo 

models=$(juju models --format json|jq .models[].name)
for model in $models
do
  model_name=$(echo $model | tr -d '"')
  if [ "$model_name" != "admin/default" ] && [ "$model_name" != "admin/controller" ]
  then
    echo "Destroying model $model_name"
    juju destroy-model -y $model_name 2> /dev/null
  fi
done

