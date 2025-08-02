#!/bin/bash
set -e

# Fix Docker socket permissions
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

# Ensure runner owns the work directory
sudo chown -R runner:runner /home/runner/_work

# Start node exporter in the background
/usr/local/bin/node_exporter --web.listen-address=":9100" &

# Configure and run the GitHub Actions runner
./config.sh --url "$REPO_URL" --token "$RUNNER_TOKEN" --unattended --replace
./run.sh