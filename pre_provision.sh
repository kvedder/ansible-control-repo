#!/bin/bash

# This script will pre-provision any Ubuntu, Debian or CentOS/Rocky Host with the Ansible User and ensure that the
# admin user and account is correctly configured.

set -e

# Variables
ANSIBLE_USER="ansible"
ANSIBLE_UID="1101"
ANSIBLE_GID="1101"
ANSIBLE_SSH_KEY="ssh-ed25519 blah blah"
ADMIN_USER="companyadmin"
ADMIN_PASSWORD="123"

# Detect OS type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS."
    exit 1
fi

# Create group with specific GID if it doesn't exist
if ! getent group "$ANSIBLE_USER" >/dev/null; then
    groupadd -g "$ANSIBLE_GID" "$ANSIBLE_USER"
    echo "Created group $ANSIBLE_USER with GID $ANSIBLE_GID"
fi

# Create ansible user with specific UID and GID if it doesn't exist
if ! id "$ANSIBLE_USER" &>/dev/null; then
    useradd -m -u "$ANSIBLE_UID" -g "$ANSIBLE_GID" -s /bin/bash "$ANSIBLE_USER"
    echo "Created user $ANSIBLE_USER with UID $ANSIBLE_UID and GID $ANSIBLE_GID"
fi

# Set up SSH for ansible user
SSH_DIR="/home/$ANSIBLE_USER/.ssh"
mkdir -p "$SSH_DIR"
echo "$ANSIBLE_SSH_KEY" > "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R "$ANSIBLE_USER:$ANSIBLE_USER" "$SSH_DIR"

echo "SSH key installed for $ANSIBLE_USER"

# Ensure admin exists
if ! id "$ADMIN_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$ADMIN_USER"
    echo "Created user $ADMIN_USER"
fi

# Set password for admin user
echo "$ADMIN_USER:$ADMIN_PASSWORD" | chpasswd
echo "Password for $ADMIN_USER set to '$ADMIN_PASSWORD'"

# Grant passwordless sudo to ansible user
SUDOERS_FILE="/etc/sudoers.d/ansible"
echo "$ANSIBLE_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
echo "Passwordless sudo granted to $ANSIBLE_USER via $SUDOERS_FILE"

echo "Done."
