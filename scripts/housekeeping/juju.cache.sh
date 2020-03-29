#!/bin/bash
#
# This script will create trusty, xenial and/or bionic lxd images that will be used by the
# lxd provider in juju 2.1+ It is for use with the lxd provider for local
# development and preinstalls a common set of packages.
#
# This is important, as between them, basenode and layer-basic install ~111
# packages, before we even get to any packages installed by your charm.
#
# It also installs some helpful development tools, and pre-downloads some
# commonly used packages.
#
# This dramatically speeds up the install hooks for lxd deploys. On my slow
# laptop, average install hook time went from ~7min down to ~1 minute.
set -eux

# The basic charm layer also installs all the things. 47 packages.
LAYER_BASIC="gcc build-essential python3-pip python3-setuptools python3-yaml"

# the basic layer also installs virtualenv, but the name changed in xenial.
TRUSTY_PACKAGES="python-virtualenv"
XENIAL_PACKAGES="virtualenv"
BIONIC_PACKAGES="virtualenv"

# Predownload common packages used by your charms in development
DOWNLOAD_PACKAGES=

PACKAGES="$LAYER_BASIC $DOWNLOAD_PACKAGES"

function cache() {
    series=$1
    container=juju-${series}-base
    alias=juju/$series/amd64

    lxc delete $container -f || true
    lxc launch ubuntu:$series $container
    sleep 15  # wait for network

    lxc exec $container -- apt update -y
    lxc exec $container -- apt upgrade -y
    lxc exec $container -- apt install -y $PACKAGES $2
    lxc stop $container

    lxc image delete $alias || true
    lxc publish $container --alias $alias description="$series juju dev image ($(date +%Y%m%d))"

    lxc delete $container -f || true
}

# Uncomment the series you need pre-cached. By default, this will only
# cache the most recent series -- currently bionic.
# cache trusty "$TRUSTY_PACKAGES"
cache xenial "$XENIAL_PACKAGES"
cache bionic "$BIONIC_PACKAGES"
