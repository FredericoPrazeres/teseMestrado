#!/bin/bash
set -e

sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

/usr/local/bin/cadvisor \
  --port=8081 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

# Use Java 21 for Jenkins
export JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-arm64
export PATH=$JAVA_HOME/bin:$PATH

# Make Java 11 available for microservices by creating an environment variable
export JAVA_11_HOME=/usr/lib/jvm/java-1.11.0-openjdk-arm64

exec java $JAVA_OPTS -jar /usr/share/jenkins.war