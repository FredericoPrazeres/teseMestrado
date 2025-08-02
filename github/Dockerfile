FROM ubuntu:22.04

ARG RUNNER_VERSION="2.327.1"

RUN apt-get update && \
    apt-get install -y curl git sudo && \
    useradd -m runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Node Exporter
RUN curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz && \
    tar -xzf node_exporter-1.8.1.linux-amd64.tar.gz && \
    mv node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/ && \
    rm -rf node_exporter-1.8.1.linux-amd64*

# Install Docker and Docker Compose
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

WORKDIR /home/runner

# Download and extract the ARM64 runner (v2.327.1)
RUN curl -o actions-runner-linux-arm64-2.327.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.327.1/actions-runner-linux-arm64-2.327.1.tar.gz && \
    echo "16102096988246f250a745c6a813a5a0b8901e2f554f9440c97e8573fd4da111  actions-runner-linux-arm64-2.327.1.tar.gz" | shasum -a 256 -c && \
    tar xzf actions-runner-linux-arm64-2.327.1.tar.gz && \
    rm actions-runner-linux-arm64-2.327.1.tar.gz

RUN chown -R runner:runner /home/runner

COPY start.sh /home/runner/start.sh
RUN chmod +x /home/runner/start.sh

# Add runner to docker group
RUN usermod -aG docker runner

# Install runner dependencies as root first
RUN ./bin/installdependencies.sh

# Switch to runner user
USER runner

ENTRYPOINT ["/home/runner/start.sh"]