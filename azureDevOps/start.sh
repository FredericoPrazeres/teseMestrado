#!/bin/bash
set -e

# Fix Docker socket permissions
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

# Start cAdvisor in the background
/usr/local/bin/cadvisor \
  --port=8080 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

# Validate required environment variables
if [ -z "$AZP_URL" ]; then
    echo "Error: AZP_URL environment variable is required"
    exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
    echo "Error: AZP_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$AZP_POOL" ]; then
    echo "Error: AZP_POOL environment variable is required"
    exit 1
fi

# Configure the agent
./config.sh \
  --unattended \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$(hostname)" \
  --replace \
  --acceptTeeEula

# Run the agent
exec ./run.sh