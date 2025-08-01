#!/bin/bash
set -e
sudo chown -R runner:runner /home/runner/_work
./config.sh --url "$REPO_URL" --token "$RUNNER_TOKEN" --unattended --replace
./run.sh