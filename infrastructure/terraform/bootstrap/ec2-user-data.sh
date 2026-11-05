#!/bin/bash

set -euxo pipefail

exec > >(tee -a /var/log/mern-bootstrap.log) 2>&1

echo "Starting MERN EC2 bootstrap..."

apt-get update

apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  awscli \
  snapd git

# Add Docker official repository
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

# Install Docker Engine and Compose plugin
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

# Allow Ubuntu user to use Docker
usermod -aG docker ubuntu

# Ensure SSM Agent is installed and running
if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic
fi

systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# Application deployment directory
mkdir -p /opt/mern-ecommerce
chown ubuntu:ubuntu /opt/mern-ecommerce

echo "Bootstrap completed."