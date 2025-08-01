#!/bin/bash

# SSH Setup Script for Docker Container
echo "🔐 Setting up SSH service..."

# Generate SSH host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Create SSH user if specified
if [ -n "$SSH_USER" ] && [ -n "$SSH_PASSWORD" ]; then
    # Create user with home directory
    useradd -m -s /bin/zsh "$SSH_USER"
    
    # Set password
    echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
    
    # Add user to sudo group for root privileges
    usermod -aG sudo "$SSH_USER"
    
    # Copy ZSH configuration to user home
    cp /root/.zshrc "/home/$SSH_USER/.zshrc"
    cp /root/.p10k.zsh "/home/$SSH_USER/.p10k.zsh"
    chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER"
    
    echo "✅ SSH user '$SSH_USER' created with sudo privileges"
fi

# Configure SSH daemon
cat > /etc/ssh/sshd_config << EOF
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Start SSH service
service ssh start

echo "✅ SSH service started on port 22"