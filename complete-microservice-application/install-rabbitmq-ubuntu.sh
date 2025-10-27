#!/bin/bash

echo "Installing RabbitMQ on Ubuntu (ARM64 compatible)..."

# Update package list
sudo apt-get update

# Install prerequisites including lsb-release
sudo apt-get install -y curl gnupg apt-transport-https lsb-release

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs)
echo "Detected Ubuntu version: $UBUNTU_VERSION"

# If detection fails, default to jammy (Ubuntu 22.04)
if [ -z "$UBUNTU_VERSION" ]; then
    echo "Could not detect Ubuntu version, defaulting to jammy"
    UBUNTU_VERSION="jammy"
fi

# Add RabbitMQ signing key
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null

# Add RabbitMQ repository
sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases
deb [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu ${UBUNTU_VERSION} main
deb-src [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu ${UBUNTU_VERSION} main

## Provides RabbitMQ
deb [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu ${UBUNTU_VERSION} main
deb-src [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu ${UBUNTU_VERSION} main
EOF

# Update package list again
sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/rabbitmq.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

# Install Erlang packages
sudo apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl

# Install RabbitMQ server
sudo apt-get install -y rabbitmq-server

# Since systemd is not available in container, start RabbitMQ manually
echo ""
echo "Starting RabbitMQ server..."

# Start RabbitMQ in detached mode
sudo rabbitmq-server -detached

# Wait for RabbitMQ to start
sleep 5

# Enable management plugin
sudo rabbitmq-plugins enable rabbitmq_management

# Wait for management plugin to load
sleep 3

# Check if RabbitMQ is running
if sudo rabbitmqctl status > /dev/null 2>&1; then
    echo ""
    echo "==========================================="
    echo "RabbitMQ Installation Complete!"
    echo "==========================================="
    echo ""
    echo "Status:"
    sudo rabbitmqctl status
    echo ""
    echo "Management Interface: http://localhost:15672"
    echo "Default credentials:"
    echo "  Username: guest"
    echo "  Password: guest"
    echo ""
    echo "Useful commands:"
    echo "  Start:   sudo rabbitmq-server -detached"
    echo "  Stop:    sudo rabbitmqctl stop"
    echo "  Status:  sudo rabbitmqctl status"
    echo "==========================================="
else
    echo "ERROR: RabbitMQ failed to start properly"
    exit 1
fi