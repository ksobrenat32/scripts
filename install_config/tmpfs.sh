#! /usr/bin/env bash

set -e

# If VAR1 is --help, -h or -?, echo short help text and exit
VAR0=$(basename "$0")
if [ "$1" = "--help" ] || [ "$1" = "-help" ] || [ "$1" = "-h" ] || [ "$1" = "-?" ]; then
    echo "Script that enables /tmp as a temporal filesystem that runs on ram."
    echo "*** For this script you need to be root."
    echo 
    echo "To encrypt a file with gpg"
    echo "	Format: '$VAR0 <Maximum size in MB>'"
    exit 1
fi

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