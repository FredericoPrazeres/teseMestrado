FROM ubuntu:22.04

ARG AGENT_VERSION=4.269.0

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl git sudo jq libicu-dev

# Create azureagent user
RUN useradd -m azureagent && \
    echo "azureagent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Docker
RUN apt-get install -y docker.io && \
    usermod -aG docker azureagent

# Install cAdvisor for monitoring
RUN curl -L https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-amd64 -o /usr/local/bin/cadvisor && \
    chmod +x /usr/local/bin/cadvisor

WORKDIR /home/azureagent

# Download and install Azure Pipelines Agent
RUN curl -o vsts-agent-linux-x64.tar.gz -L https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-arm64-${AGENT_VERSION}.tar.gz && \
    tar xzf vsts-agent-linux-x64.tar.gz && \
    rm vsts-agent-linux-x64.tar.gz

# Install agent dependencies
RUN ./bin/installdependencies.sh

# Create necessary directories with proper permissions
RUN mkdir -p /home/azureagent/_work && \
    mkdir -p /home/azureagent/_diag && \
    chown -R azureagent:azureagent /home/azureagent

COPY start.sh /home/azureagent/start.sh
RUN chmod +x /home/azureagent/start.sh && \
    chown azureagent:azureagent /home/azureagent/start.sh

USER azureagent

ENTRYPOINT ["/home/azureagent/start.sh"]