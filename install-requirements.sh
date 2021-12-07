#!/bin/bash
##
# Install all the requirements
#

apt-get update
export DEBIAN_FRONTEND="noninteractive"
apt-get install -y lftp wget perl make gcc libxml2-utils libfile-slurp-perl
