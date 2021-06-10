#! /usr/bin/env bash

# This script needs to be run as root
# This script enables /tmp as a temporal filesystem that runs on ram.

set -e

if ! [[ "$(id -u)" = 0 ]]; then
    echo "Error, this script needs to be run as root"
    exit 127
fi

_size=$1
_re='^[0-9]+$'

if [ -z "$_size" ]; then
    echo "You are mising the size,continuing with the default, half of the ram size."
	echo "tmpfs /tmp tmpfs rw,nosuid,noatime,nodev,mode=1777 0 0" >> /etc/fstab
    exit 0
fi

if ! [[ $_size =~ $_re ]] ; then
    echo "error: The size is not a number, remember it needs to be size in MB" 
    exit 1
fi

if (( "$_size" > "$_ram_size" )); then
	echo "error: The maximum is the size your ram, which is $_ram_size MB"
	exit 2
fi

echo "tmpfs /tmp tmpfs rw,nosuid,noatime,nodev,size=${_size}M,mode=1777 0 0" >> /etc/fstab
exit 0