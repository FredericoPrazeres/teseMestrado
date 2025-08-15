#!/bin/bash

echo "🚀 Starting GitLab Runner Registration"
echo "======================================"

# Validate environment variables
if [ -z "$GITLAB_URL" ]; then
    echo "❌ GITLAB_URL environment variable is required"
    exit 1
fi

if [ -z "$GITLAB_REGISTRATION_TOKEN" ]; then
    echo "❌ GITLAB_REGISTRATION_TOKEN environment variable is required"
    exit 1
fi

echo "GitLab URL: $GITLAB_URL"
echo "Token format: ${GITLAB_REGISTRATION_TOKEN:0:5}..."

# Test connectivity to GitLab
echo "🔍 Testing GitLab connectivity..."
if ! curl -s --connect-timeout 10 "$GITLAB_URL" > /dev/null; then
    echo "❌ Cannot reach GitLab at $GITLAB_URL"
    exit 1
fi
echo "✅ GitLab is reachable"

# Ensure config directory exists
mkdir -p /home/gitlab-runner/.gitlab-runner
chmod 755 /home/gitlab-runner/.gitlab-runner

# Register the runner with minimal configuration (new token format)
echo "📝 Registering runner with new authentication token..."
gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --token "$GITLAB_REGISTRATION_TOKEN" \
  --name "gitlab-runner-docker-$(hostname)" \
  --executor "shell" \
  --config /home/gitlab-runner/.gitlab-runner/config.toml

# Verify registration
if [ $? -eq 0 ]; then
    echo "✅ Runner registration completed successfully"
    
    # Check config file
    if [ -f /home/gitlab-runner/.gitlab-runner/config.toml ]; then
        echo "📄 Configuration file created:"
        cat /home/gitlab-runner/.gitlab-runner/config.toml
    else
        echo "❌ Configuration file not found"
        exit 1
    fi
else
    echo "❌ Runner registration failed"
    exit 1
fi

echo "🎉 Registration process completed"