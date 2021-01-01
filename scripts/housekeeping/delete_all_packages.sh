#!/bin/bash

# Deletes all network service and vnf descriptors

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$token" ]; then
  source ../get_token.sh;
fi

nsds=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://${OSM_HOSTNAME}:9999/osm/nsd/v1/ns_descriptors | yq e '.[].id' -)

for nsd in $nsds
do
  osm nsd-delete $nsd
done


vnfds=$(curl --silent --insecure -H "Content-Type: application/yaml" -H "Authorization: Bearer $token" -H "Accept: application/yaml" -X GET  https://${OSM_HOSTNAME}:9999/osm/vnfpkgm/v1/vnf_packages | yq e '.[].id' -)

for vnfd in $vnfds
do
  osm vnfd-delete $vnfd
done


	
