#!/bin/bash
set -e  # Exit on any error

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

# Stage 2: Stop current microservices (keep db running)
log "=== STOPPING CURRENT MICROSERVICES ==="
log "Stopping microservices: $MICROSERVICES"
for service in $MICROSERVICES; do
    docker-compose -f $DOCKER_COMPOSE_FILE stop $service || true
done

log "Removing microservice containers: $MICROSERVICES"
for service in $MICROSERVICES; do
    docker-compose -f $DOCKER_COMPOSE_FILE rm -f $service || true
done

# Clean up unused images
log "Cleaning up unused Docker images..."
docker image prune -f || true

# Stage 3: Deploy all services with build
log "=== BUILDING AND DEPLOYING SERVICES ==="
log "Running docker-compose up --build for all services..."

docker compose up --build

if [ $? -eq 0 ]; then
    log "Services built and started successfully"
    log "Waiting for services to initialize..."
    sleep 60
else
    error "Failed to build and start services"
    exit 1
fi

# Stage 4: Health check
log "=== HEALTH CHECK ==="
log "Performing health check on API interface..."

timeout 300 bash -c '
    while ! curl -f http://localhost:8082/jobs/search/best-companies >/dev/null 2>&1; do
        echo "Waiting for API to be ready..."
        sleep 5
    done
' || {
    error "Health check failed - rolling back microservices"
    for service in $MICROSERVICES; do
        docker-compose -f $DOCKER_COMPOSE_FILE stop $service || true
    done
    exit 1
}

log "✓ Health check passed - Services are healthy!"

# Stage 5: Show status
log "=== DEPLOYMENT COMPLETE ==="
docker-compose -f $DOCKER_COMPOSE_FILE ps
log "🎉 Deployment successful!"
log "Services status:"
log "- Database: http://localhost:5432"
log "- API Interface: http://localhost:8082"
log "- Job Postings: http://localhost:8081"
log "- Job Reviews: http://localhost:8084"
log "- Data Access: http://localhost:8083"
log "- Jenkins: http://localhost:8080"