#!/bin/bash

# Start cAdvisor
/usr/local/bin/cadvisor \
  --port=8080 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

# Very important! Otherwise the runner will not be able to connect to the Docker daemon.
chown root:docker /var/run/docker.sock
chmod 777 /var/run/docker.sock

echo "Starting GitLab Runner Container with cAdvisor"
echo "=============================================="

mkdir -p /home/gitlab-runner/.gitlab-runner

# Runner registration check
if [ ! -f /home/gitlab-runner/.gitlab-runner/config.toml ] || [ ! -s /home/gitlab-runner/.gitlab-runner/config.toml ]; then
    echo "No existing runner configuration found. Registering new runner..."
    
    # Run registration
    /usr/local/bin/register-runner.sh
    
    # Verify registration was successful
    if [ ! -s /home/gitlab-runner/.gitlab-runner/config.toml ]; then
        echo "❌ Registration failed - config file is empty"
        cat /home/gitlab-runner/.gitlab-runner/config.toml 2>/dev/null || echo "Config file doesn't exist"
        exit 1
    fi
else
    echo "Existing runner configuration found. Skipping registration."
fi

echo "Configuration file contents:"
cat /home/gitlab-runner/.gitlab-runner/config.toml

echo "Starting GitLab Runner service..."

# Remove bash logout to prevent issues with bash shell
rm /home/gitlab-runner/.bash_logout


# Specifying the config file is essential, otherwise the runner will be offline.
exec gitlab-runner run --user gitlab-runner --working-directory /home/gitlab-runner --config /home/gitlab-runner/.gitlab-runner/config.toml