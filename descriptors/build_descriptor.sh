#!/bin/bash

# Assumes there is a single file name for the vnfd and the ns
# Must be executed with the descriptor name as a parameter

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESCRIPTORS_DIR="$THIS_DIR"

function build_descriptor(){
	descriptor_name=$1;

	echo "Building $descriptor_name";

	cd $DESCRIPTORS_DIR/${descriptor_name};

	# Delete packages
	rm *_ns.tar.gz
	rm *_vnf.tar.gz

	# Generate checksums
	cd ${descriptor_name}_vnf;
	find . -type f -exec md5sum {} + > checksums.txt;
	cd ..;

	cd ${descriptor_name}_ns;
	find . -type f -exec md5sum {} + > checksums.txt;
	cd ..;

	# Generate packages
	tar -czf ${descriptor_name}_vnf.tar.gz ${descriptor_name}_vnf
	tar -czf ${descriptor_name}_ns.tar.gz ${descriptor_name}_ns

}

build_descriptor $1;

