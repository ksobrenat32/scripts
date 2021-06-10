#! /bin/bash

## This script needs to be run as root
## This script enables a zram module.

set -e

if ! [[ "$(id -u)" = 0 ]]; then
    echo "Error, this script needs to be run as root"
    exit 127
fi

_size=$1
_ram_size=$(( $(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }') / 1024 ))
_re='^[0-9]+$'

if [ -z "$_size" ]; then
    echo "You are mising the size,continuing with the half of the ram size."
	_size=$(($(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }') /2 / 1024 ))
fi

if ! [[ $_size =~ $_re ]] ; then
   echo "error: The size is not a number" 
   exit 1
fi

if (( "$_size" > "$_ram_size" )); then
	echo "error: The maximum is the size your ram, which is $_ram_size MB"
	exit 2
fi

__k='KERNEL=="zram0", ATTR{disksize}="'
__t='M",TAG+="systemd"'

echo "${__k}${_size}${__t}" >> /etc/udev/rules.d/99-zram.rules
echo 'zram' >> /etc/modules-load.d/zram.conf
echo 'options zram num_devices=1' >> /etc/modprobe.d/zram.conf

cat >> /etc/systemd/system/zram.service <<EOF
[Unit]
Description=Swap with zram
After=multi-user.target

[Service]
Type=oneshot 
RemainAfterExit=true
ExecStartPre=/sbin/mkswap /dev/zram0
ExecStart=/sbin/swapon /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable zram