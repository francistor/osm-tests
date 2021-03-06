#!/bin/bash

# Deletes all network service descriptors

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$token" ]; then
  source ../get_token.sh;
fi

nss=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET https://${OSM_HOSTNAME}:9999/osm/nslcm/v1/ns_instances | yq e .[]._id -)

for ns in $nss
do
  echo deleting $ns
  osm ns-delete $ns
done


