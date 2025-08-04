#!/bin/bash
set -e

/usr/local/bin/cadvisor \
  --port=8081 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

exec java $JAVA_OPTS -jar /usr/share/jenkins.war