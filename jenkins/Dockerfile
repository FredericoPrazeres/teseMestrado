FROM ubuntu:22.04

ENV JENKINS_VERSION=2.516.1
ENV JENKINS_HOME=/var/jenkins_home
ENV JENKINS_USER=jenkins
ENV JENKINS_GROUP=jenkins

# Install dependencies
RUN apt-get update && \
    apt-get install -y openjdk-21-jdk curl git sudo docker.io && \
    groupadd -g 1000 ${JENKINS_GROUP} && \
    useradd -m -d ${JENKINS_HOME} -u 1000 -g ${JENKINS_GROUP} ${JENKINS_USER} && \
    echo "${JENKINS_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Docker and Docker Compose
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install cAdvisor
RUN curl -L https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-amd64 -o /usr/local/bin/cadvisor && \
    chmod +x /usr/local/bin/cadvisor

# Download Jenkins WAR
RUN curl -L https://get.jenkins.io/war-stable/${JENKINS_VERSION}/jenkins.war -o /usr/share/jenkins.war

# Set permissions
RUN chown -R ${JENKINS_USER}:${JENKINS_GROUP} ${JENKINS_HOME}

WORKDIR /home/scripts

RUN chown -R jenkins:jenkins /home/scripts

# Copy start script
COPY start.sh /home/scripts/start.sh
RUN chmod +x /home/scripts/start.sh

RUN usermod -aG docker ${JENKINS_USER}

USER ${JENKINS_USER}

ENTRYPOINT ["/home/scripts/start.sh"]