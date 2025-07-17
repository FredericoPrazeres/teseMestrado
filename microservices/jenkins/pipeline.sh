#!/bin/bash
set -e  # Exit on any error

# Configuration
DOCKER_COMPOSE_FILE="docker-compose.yml"
SERVICES="db data-access job-postings job-reviews api-interface"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Stage 1: Checkout info
log "=== CHECKOUT STAGE ==="
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
log "Building commit: $GIT_COMMIT_HASH"
log "Working directory: $(pwd)"

# Stage 2: Stop current services
log "=== STOPPING CURRENT SERVICES ==="
log "Stopping services: $SERVICES"
for service in $SERVICES; do
    docker-compose -f $DOCKER_COMPOSE_FILE stop $service || true
done

log "Removing containers: $SERVICES"
for service in $SERVICES; do
    docker-compose -f $DOCKER_COMPOSE_FILE rm -f $service || true
done

docker system prune -f || true

# Stage 3: Build services
log "=== BUILDING SERVICES ==="
for service in $SERVICES; do
    log "Building $service..."
    docker-compose -f $DOCKER_COMPOSE_FILE build --no-cache $service
    if [ $? -eq 0 ]; then
        log "✓ $service built successfully"
    else
        error "✗ Failed to build $service"
        exit 1
    fi
done

# Stage 4: Deploy services
log "=== DEPLOYING SERVICES ==="
docker-compose -f $DOCKER_COMPOSE_FILE up -d $SERVICES

if [ $? -eq 0 ]; then
    log "Services started successfully"
    log "Waiting for services to initialize..."
    sleep 60
else
    error "Failed to start services"
    exit 1
fi

# Stage 5: Health check
log "=== HEALTH CHECK ==="
timeout 300 bash -c '
    while ! curl -f http://localhost:8082/jobs/search/best-companies >/dev/null 2>&1; do
        echo "Waiting for API to be ready..."
        sleep 5
    done
' || {
    error "Health check failed - rolling back"
    for service in $SERVICES; do
        docker-compose -f $DOCKER_COMPOSE_FILE stop $service || true
    done
    exit 1
}

log "✓ Health check passed - Services are healthy!"

# Show status
log "=== DEPLOYMENT COMPLETE ==="
docker-compose -f $DOCKER_COMPOSE_FILE ps $SERVICES
log "🎉 Deployment successful!"