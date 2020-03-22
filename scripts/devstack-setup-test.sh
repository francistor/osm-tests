#!/bin/bash

# Update the quota for the number of instances
openstack quota set --instances 100 $(openstack project show -f value -c id test-project)
# Update the quota for the number of CPU
openstack quota set --cores 100 $(openstack project show -f value -c id test-project)

# Create my_security_group
openstack security group create my_security_group
sec_group=$(openstack security group list|grep my_security_group|cut -d " " -f 2)
openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 $sec_group
openstack security group rule create --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 22 $sec_group
