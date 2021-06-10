#! /usr/bin/env bash

# This script enables linger for your user, docker registrie and enable ping from non root co ntainers.

set -e
__username=$(whoami)

# Enable ping on non root containers
sudo echo 'net.ipv4.ping_group_range=0 165535' >> /etc/sysctl.d/podman-ping.conf

# Add podman registrie
echo -e "[registries.search]\nregistries = ['docker.io']" | tee $HOME/.config/containers/registries.conf

# Enable linger for your user
sudo loginctl enable-linger $__username