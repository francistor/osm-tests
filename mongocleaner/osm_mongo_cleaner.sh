#!/bin/bash

if [[ "$1" = "--help" ]] 
then
    echo "usage: osm_mongo_cleaner.sh [orphan-folders|orphan-files|mark-orphans|delete-orphans|revert-orphans]";
    exit 0;
fi

if [[ "$1" != "orphan-folders" ]] &&  [[ "$1" != "orphan-files" ]] && [[ "$1" != "mark-orphans" ]] &&  [[ "$1" != "delete-orphans" ]] && [[ "$1" != "revert-orphans" ]] 
then
    echo "Bad command. Must be one of [orphan-folders|orphan-files|mark-orphans|delete-orphans|revert-orphans]";
    exit 0;
fi

# Do the job
# Use brackets to concat the stdout. First, define a variable with the command to execute.
{ echo "var action=\""$1"\""; cat osm_mongo_cleaner.js; } | kubectl exec -i -c mongodb-k8s -n osm mongodb-k8s-0 -- mongo --quiet