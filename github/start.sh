#!/bin/bash
set -e

# Fix Docker socket permissions
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

# Ensure runner owns the work directory
sudo chown -R runner:runner /home/runner/_work

# Start cAdvisor in the background
/usr/local/bin/cadvisor \
  --port=8080 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &


# Configure and run the GitHub Actions runner
./config.sh --url "$REPO_URL" --token "$RUNNER_TOKEN" --unattended --replace
./run.sh