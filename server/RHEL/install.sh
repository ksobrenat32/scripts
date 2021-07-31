#! /usr/bin/env bash
set -e
set -u

# Variables to change
username='<username>'
password='<password>'
host_name='<hostname>'
sshkey='<your ssh key>'
sshport='<the port you want to use>'
pro_ins='<programs you want to install (with a space between them)>'
tz='<your timezone>'

dnf update -y
dnf install -y epel-release
#Installing asked software
dnf install -y ${pro_ins}

# Setting up the non-root user
dnf install -y sudo
useradd --create-home "${username}"
echo "${password}" | passwd --stdin "${username}"
echo '%wheel	ALL=(ALL)	ALL' | tee -a /etc/sudoers
usermod -a -G wheel "${username}"
usermod -L root

# Setting up timezone
timedatectl set-timezone ${tz}

# Changing hostname
hostnamectl set-hostname ${host_name}

# Setting up ssh configuration
mkdir -p /home/${username}/.ssh/
echo "${sshkey}" >> /home/${username}/.ssh/authorized_keys
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat <<EOF | tee /etc/ssh/sshd_config
# Custom sshd configuration file

# Specify a port
Port ${sshport}

# Default of centos sshd_config
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
SyslogFacility AUTHPRIV
AuthorizedKeysFile      .ssh/authorized_keys
ChallengeResponseAuthentication no

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
dnf install -y policycoreutils-python-utils
semanage port -a -t ssh_port_t -p tcp ${sshport}
systemctl restart sshd.service
firewall-cmd --permanent --remove-service=ssh
firewall-cmd --permanent --add-port=${sshport}/tcp
firewall-cmd --reload

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
ExecStart=/usr/bin/dnf upgrade -y

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