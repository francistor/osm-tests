#!/bin/bash

source $HOME/test-devstack.rc

curl -L -o $HOME/bionic-server-cloudimg-amd64.img http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
curl -L -o $HOME/cirros-0.4.0-x86_64-disk.img http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img


openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/bionic-server-cloudimg-amd64.img bionic-cloud
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/cirros-0.4.0-x86_64-disk.img cirros_with_pw
