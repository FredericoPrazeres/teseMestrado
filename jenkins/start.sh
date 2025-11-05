#!/bin/bash
set -e

sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

/usr/local/bin/cadvisor \
  --port=8081 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

exec java $JAVA_OPTS -jar /usr/share/jenkins.war