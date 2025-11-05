#!/bin/bash
set -e

sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

if [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
elif [ -d "/usr/lib/jvm/java-11-openjdk-arm64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
elif [ -d "/usr/lib/jvm/java-11-openjdk" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
else
    # Try to find Java 11 automatically
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
fi

export PATH=$JAVA_HOME/bin:$PATH

/usr/local/bin/cadvisor \
  --port=8081 \
  --prometheus_endpoint="/metrics" \
  --docker_only=true \
  --housekeeping_interval=30s &

exec java $JAVA_OPTS -jar /usr/share/jenkins.war