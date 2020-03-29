#!/bin/bash

# Deletes all models in juju

source $HOME/test-osm.rc

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

