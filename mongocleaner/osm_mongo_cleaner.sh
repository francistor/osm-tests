#!/bin/bash

if [[ "$1" = "--help" ]] 
then
    echo "usage: osm_mongo_cleaner.sh [orphan-folders|orphan-files|mark-orphans|delete-orphans|revert-orphans|all-files|all-folders]";
    echo "Execute in the machine where mongod is installed";
    echo "  Utility to remove orphan files, that is, not corresponding to any ns, nsd, vnfd or k8scluster active in OSM";
    echo "  Standard usage consists on executing with the mark-orphans option, which will rename the orphan files to include";
    echo "  the string ORPHAN_ as a prefix, and then with the delete-orphans option, which will remove those files";
    echo "  This is done for safety: the user may check that the initial step does not do any harm, or revert with revert-orphans";
    echo "  if necessary.";
    echo "";
    echo "  COMMANDS";
    echo "    orphan-folders: shows the orphan folders. No changes are performed";
    echo "    orphan-files: shows all the orphan files. No changes are performed";
    echo "    mark-orphans: prepeds ORPHAN_ to any orphan files";
    echo "    delete-orphans: deletes the files marked as orphan in the previous step";
    echo "    revert-orphans: removes the ORPHAN_ prefix in any files";
    echo "    all-files: list all files, orphan or not";
    echo "    all-folders: list all folders, orphan or not";
    exit 0;
fi

if [[ "$1" != "orphan-folders" ]] &&  [[ "$1" != "orphan-files" ]] && [[ "$1" != "mark-orphans" ]] &&  [[ "$1" != "delete-orphans" ]] && [[ "$1" != "revert-orphans" ]] && [[ "$1" != "all-files" ]] && [[ "$1" != "all-folders" ]]
then
    echo "Bad command. Must be one of [orphan-folders|orphan-files|mark-orphans|delete-orphans|revert-orphans]";
    exit 0;
fi

# Do the job
# Use brackets to concat the stdout. First, define a variable with the command to execute.
# Use this if executing from outside mongo but having access to kubectl
{ echo "var action=\""$1"\""; cat osm_mongo_cleaner.js; } | kubectl exec -i -c mongodb-k8s -n osm mongodb-k8s-0 -- mongo --quiet

# With access to mongo
# { echo "var action=\""$1"\""; cat osm_mongo_cleaner.js; } | mongo --quiet
