#!/bin/bash

# Assumes there is a single file name for the vnfd and the ns
# Must be executed with the descriptor name as a parameter

destination=francisco@n2
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESCRIPTORS_DIR="$THIS_DIR"

function build_descriptor(){
	descriptor_name=$1;

	cd $DESCRIPTORS_DIR/${descriptor_name};

	# Delete packages
	rm ${descriptor_name}_ns.tar.gz > /dev/null
	rm ${descriptor_name}_vnf.tar.gz > /dev/null

	# Generate checksums
	cd ${descriptor_name}_vnf;
	find . -type f -exec md5sum {} + > checksums.txt;
	cd ..;

	cd ${descriptor_name}_ns;
	find . -type f -exec md5sum {} + > checksums.txt;
	cd ..;

	# Generate packages
	tar -czvf ${descriptor_name}_vnf.tar.gz ${descriptor_name}_vnf
	tar -czvf ${descriptor_name}_ns.tar.gz ${descriptor_name}_ns

	# Delete in parent
	ssh $destination rm ${descriptor_name}_vnf.tar.gz ${descriptor_name}_ns.tar.gz

	# Upload to parent
	scp ${descriptor_name}_vnf.tar.gz $destination
	scp ${descriptor_name}_ns.tar.gz $destination
}

build_descriptor $1;

