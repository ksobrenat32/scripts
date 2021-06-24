#! /usr/bin/env bash

# This script enables linger for your user, docker registrie and enable ping from non root co ntainers.

set -e
__username=$(whoami)

# Enable ping on non root containers
echo -e 'net.ipv4.ping_group_range=0 165535' | sudo tee /etc/sysctl.d/podman-ping.conf

# Add podman registrie
mkdir -p $HOME/.config/containers/
echo -e "[registries.search]\nregistries = ['docker.io']" | tee $HOME/.config/containers/registries.conf

# Enable linger for your user
sudo loginctl enable-linger $__username

# Install podman compose
pip install -U podman-compose