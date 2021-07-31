#! /usr/bin/env bash
set -e

# This script is for installing when using debian images from https://raspi.debian.net/

# Variables to change
username='<username>'
password='<password>'
host_name='<hostname>'
sshkey='<your ssh key>'
sshport='<the port you want to use>'
pro_ins='<programs you want to install (with a space between them)>'
tz='<your timezone>'

apt update -y
apt upgrade -y

# Setting up locales
apt install locales -y
locale-gen --purge "en_US.UTF-8"
dpkg-reconfigure --frontend noninteractive locales

# Setting up timezone
timedatectl set-timezone ${tz}

#Installing asked software
apt install -y ${pro_ins}

# Setting up the non-root user
apt install -y sudo
useradd "${username}"
echo -e "${password}\n${password}" | passwd "${username}"
echo '%sudo   ALL=(ALL:ALL) ALL' | tee -a /etc/sudoers
usermod -a -G sudo "${username}"
usermod -L root

# Changing hostname
hostnamectl set-hostname ${host_name}
echo "127.0.0.1    	localhost.localdomain localhost" | tee -a /etc/hosts
echo "127.0.0.1    	${host_name}" | tee -a /etc/hosts

# Setting up ssh configuration
mkdir -p /home/${username}/.ssh
echo "${sshkey}" >> /home/${username}/.ssh/authorized_keys
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat <<EOF | tee /etc/ssh/sshd_config
# Custom sshd configuration file

# Specify a port
Port ${sshport}

PermitRootLogin no
MaxAuthTries 5
MaxSessions 5
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv no
Subsystem sftp /usr/lib/openssh/sftp-server
PubkeyAuthentication yes

# Specify the users that are able to login using ssh
AllowUsers ${username}
EOF
systemctl restart ssh

# To prevent privilege-escalation and arbitrary script execution, create a separate tmpfs for /tmp
echo  >> /etc/fstab
echo '## tmp in tmpfs' >> /etc/fstab
echo 'tmpfs /tmp tmpfs defaults,nosuid,nodev,noexec 0 0' >> /etc/fstab

# Enable automatic upgrades
cat <<EOF | tee /etc/systemd/system/unattended_upgrades.service
[Unit]
Description=Run a dnf upgrade daily
Wants=unattended_upgrades.timer

[Service]
Type=oneshot
ExecStart=/usr/bin/apt update -y
ExecStart=/usr/bin/apt upgrade -y

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF | tee /etc/systemd/system/unattended_upgrades.timer
[Unit]
Description=Run a dnf upgrade daily
Requires=unattended_upgrades.service

[Timer]
Unit=unattended_upgrades.service
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl enable unattended_upgrades.timer