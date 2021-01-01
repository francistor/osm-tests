#!/bin/bash

source $HOME/test-devstack.rc


curl -L -o $HOME/images/xenial-server-cloudimg-amd64-disk1.img http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img 
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/images/xenial-server-cloudimg-amd64-disk1.img ubuntu16.04
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/images/xenial-server-cloudimg-amd64-disk1.img US1604

curl -L -o $HOME/images/bionic-server-cloudimg-amd64.img http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/images/bionic-server-cloudimg-amd64.img ubuntu18.04

curl -L -o $HOME/images/vyos-1.1.7-cloudinit.qcow2 https://osm-download.etsi.org/ftp/osm-6.0-six/7th-hackfest/images/vyos-1.1.7-cloudinit.qcow2
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/images/vyos-1.1.7-cloudinit.qcow2 vyos-1.1.7

curl -L -o $HOME/images/cirros-0.4.0-x86_64-disk.img http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create --shared --disk-format qcow2 --container-format bare --file $HOME/images/cirros-0.4.0-x86_64-disk.img cirros_with_pw
