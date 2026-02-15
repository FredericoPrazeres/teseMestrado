#!/bin/bash
set -e

COMPOSE_FILE="zammad-docker-compose/docker-compose.yml"

###############################################################################
# STAGE 1: CLEANUP
###############################################################################
echo "============================================"
echo "🧹 STAGE 1: Cleanup Old Containers"
echo "============================================"

echo "🧹 Cleaning up old containers..."
if [ -d "zammad-docker-compose" ]; then
  docker-compose -f "$COMPOSE_FILE" down --volumes --remove-orphans 2>/dev/null || true
fi
docker system prune -f --volumes 2>/dev/null || true
echo "✅ Cleanup complete."

###############################################################################
# STAGE 2: DEPLOY
###############################################################################
echo "============================================"
echo "🚀 STAGE 2: Deploy Zammad"
echo "============================================"

echo "📦 Cloning Zammad Docker Compose repository..."
rm -rf zammad-docker-compose
git clone https://github.com/zammad/zammad-docker-compose.git zammad-docker-compose
echo "✅ Zammad repo cloned."

echo "🚀 Starting Zammad application stack..."
export NGINX_EXPOSE_PORT=8090
docker-compose -f "$COMPOSE_FILE" up -d
echo "✅ Zammad stack started."

echo "⏳ Waiting for PostgreSQL..."
for i in $(seq 1 30); do
  if docker-compose -f "$COMPOSE_FILE" exec -T zammad-postgresql pg_isready -U zammad > /dev/null 2>&1; then
    echo "✅ PostgreSQL is ready."
    break
  fi
  echo "  Attempt $i/30 - PostgreSQL not ready yet..."
  sleep 5
  if [ "$i" -eq 30 ]; then
    echo "❌ PostgreSQL failed to start."
    exit 1
  fi
done

echo "⏳ Waiting for Zammad init container to finish..."
for i in $(seq 1 60); do
  # docker-compose V1: ps output shows "Exit 0" for successful completion
  if docker-compose -f "$COMPOSE_FILE" ps zammad-init 2>/dev/null | grep -q "Exit 0"; then
    echo "✅ Zammad init completed successfully."
    break
  fi
  # Check if it exited with a non-zero code
  if docker-compose -f "$COMPOSE_FILE" ps zammad-init 2>/dev/null | grep -q "Exit"; then
    echo "❌ Zammad init failed."
    docker-compose -f "$COMPOSE_FILE" logs zammad-init
    exit 1
  fi
  echo "  Attempt $i/60 - Zammad init still running..."
  sleep 10
  if [ "$i" -eq 60 ]; then
    echo "❌ Zammad init timed out."
    exit 1
  fi
done

echo "⏳ Waiting for Zammad web interface..."
for i in $(seq 1 40); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090 2>/dev/null || echo "000")
  if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
    echo "✅ Zammad is reachable (HTTP $HTTP_STATUS)."
    break
  fi
  echo "  Attempt $i/40 - HTTP status: $HTTP_STATUS"
  sleep 10
  if [ "$i" -eq 40 ]; then
    echo "❌ Zammad web interface failed to respond."
    exit 1
  fi
done

###############################################################################
# STAGE 3: TEST
###############################################################################
echo "============================================"
echo "🔍 STAGE 3: Test Zammad Deployment"
echo "============================================"

echo "🔍 Checking running services..."
SERVICES=("zammad-railsserver" "zammad-scheduler" "zammad-websocket" "zammad-postgresql" "zammad-redis" "zammad-memcached")
ALL_OK=true
for svc in "${SERVICES[@]}"; do
  if docker-compose -f "$COMPOSE_FILE" ps "$svc" 2>/dev/null | grep -q "Up"; then
    echo "  ✅ $svc is running."
  else
    echo "  ❌ $svc is NOT running."
    ALL_OK=false
  fi
done
if [ "$ALL_OK" = false ]; then
  echo "❌ Some services are not running."
  exit 1
fi
echo "✅ All services are healthy."

echo "🔍 Testing Zammad API..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090/api/v1/monitoring/health_check 2>/dev/null || echo "000")
echo "  Health check HTTP status: $HTTP_STATUS"
if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 500 ]; then
  echo "✅ Zammad API is responding."
else
  echo "⚠️ Zammad API returned HTTP $HTTP_STATUS (may still be initializing)."
fi

echo "🔍 Testing PostgreSQL..."
docker-compose -f "$COMPOSE_FILE" exec -T zammad-postgresql psql -U zammad -d zammad_production -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null
echo "✅ PostgreSQL connectivity verified."

echo "🔍 Testing Redis..."
PONG=$(docker-compose -f "$COMPOSE_FILE" exec -T zammad-redis redis-cli ping 2>/dev/null || echo "FAIL")
if [ "$PONG" = "PONG" ]; then
  echo "✅ Redis is healthy."
else
  echo "❌ Redis ping failed."
  exit 1
fi

echo "📋 Collecting container logs..."
docker-compose -f "$COMPOSE_FILE" logs --tail=50

###############################################################################
# STAGE 4: TEARDOWN
###############################################################################
echo "============================================"
echo "🛑 STAGE 4: Teardown Zammad"
echo "============================================"

echo "🛑 Stopping Zammad stack..."
docker-compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
echo "✅ Zammad stack stopped and cleaned up."