FROM jenkins/jenkins:lts

USER root

# Install Docker and Docker Compose
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    usermod -aG docker jenkins

RUN mkdir -p /var/jenkins_home/workspace/datasets && \
    chown -R jenkins:jenkins /var/jenkins_home/workspace

USER jenkins