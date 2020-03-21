#!/bin/bash

# Copies the asset files to the OSM host
# The name of the host is the first parameter. n2 is used as default

destination=$1
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $THIS_DIR;

# Delete the contents in the destination
ssh ${destination:-n2} "rm -rf osm-tests && mkdir osm-tests"

# Copy contents
scp -r ../osm-tests ${destination:-n2}:.
