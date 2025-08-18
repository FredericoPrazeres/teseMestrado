FROM ubuntu:22.04

#Variável de ambiente
ENV GITLAB_RUNNER_VERSION="18.1.3"

RUN apt-get update && \
    apt-get install -y curl git sudo ca-certificates && \
    useradd -m gitlab-runner && \
    echo "gitlab-runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN curl -L https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-amd64 -o /usr/local/bin/cadvisor && \
    chmod +x /usr/local/bin/cadvisor

RUN apt-get update && \
    apt-get install -y docker.io curl && \
    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash && \
    apt-get install -y gitlab-runner

RUN mkdir -p /home/gitlab-runner/.gitlab-runner && \
    chown -R gitlab-runner:gitlab-runner /home/gitlab-runner

RUN usermod -aG docker root
RUN usermod -aG docker gitlab-runner

COPY register-runner.sh /usr/local/bin/register-runner.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/register-runner.sh /entrypoint.sh

# Don't switch to gitlab-runner user - stay as root
# USER gitlab-runner

ENTRYPOINT ["/entrypoint.sh"]