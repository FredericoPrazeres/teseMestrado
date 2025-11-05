#!/bin/bash
set -e

# This script replicates the GitHub Actions workflow logic for Jenkins
# It detects changes in microservices and builds only what's necessary

WORKSPACE_PATH="${WORKSPACE:-/var/jenkins_home/workspace/microservices-pipeline}"
APP_BASE="$WORKSPACE_PATH/complete-microservice-application"

# Java 11 for microservices
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

echo "=== Jenkins Pipeline for Microservices ==="
echo "Workspace: $WORKSPACE_PATH"
echo "Java Version: $(java -version 2>&1 | head -n 1)"
echo "Maven Version: $(mvn -version | head -n 1)"

# Function to detect changes in a directory
detect_changes() {
    local service_path=$1
    local service_name=$2
    
    echo "Checking for changes in $service_name..."
    
    # If this is the first build or GIT_PREVIOUS_COMMIT is not set, build everything
    if [ -z "$GIT_PREVIOUS_COMMIT" ] || [ "$GIT_PREVIOUS_COMMIT" = "$GIT_COMMIT" ]; then
        echo "✅ First build or no previous commit - building $service_name"
        return 0
    fi
    
    # Check if there are changes in the service directory
    if git diff --name-only $GIT_PREVIOUS_COMMIT $GIT_COMMIT | grep -q "$service_path"; then
        echo "✅ Detected changes in $service_name"
        return 0
    else
        echo "❌ No changes in $service_name"
        return 1
    fi
}

# Function to wait for service health
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-180}
    
    echo "Waiting for $service_name to be ready at $url..."
    for i in $(seq 1 $max_attempts); do
        if curl -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name is ready!"
            return 0
        fi
        echo "Attempt $i/$max_attempts - waiting..."
        sleep 2
    done
    
    echo "⚠️  $service_name did not become ready in time"
    return 1
}

# Clean workspace permissions
echo "=== Fixing workspace permissions ==="
sudo chown -R jenkins:jenkins $WORKSPACE_PATH 2>/dev/null || true
sudo chmod -R u+w $WORKSPACE_PATH 2>/dev/null || true
sudo rm -rf $APP_BASE/*/target || true

# Ensure RabbitMQ is running
echo "=== Checking RabbitMQ ==="
if ! docker ps | grep -q rabbitmq; then
        docker run -d --name rabbitmq \
          -p 5672:5672 -p 15672:15672 \
          -e RABBITMQ_DEFAULT_USER=guest \
            -e RABBITMQ_DEFAULT_PASS=guest \
            rabbitmq:3-management || echo "RabbitMQ already running or failed to start"
          
fi
echo "✅ RabbitMQ is running"

# Detect changes for each service
SERVICE_REGISTRY_CHANGED=false
API_GATEWAY_CHANGED=false
PRODUCT_SERVICE_CHANGED=false
OFFER_SERVICE_CHANGED=false
MICROSERVICE_UI_CHANGED=false

if detect_changes "service-registry" "service-registry"; then
    SERVICE_REGISTRY_CHANGED=true
fi

if detect_changes "api-gateway" "api-gateway"; then
    API_GATEWAY_CHANGED=true
fi

if detect_changes "product-service" "product-service"; then
    PRODUCT_SERVICE_CHANGED=true
fi

if detect_changes "offer-service" "offer-service"; then
    OFFER_SERVICE_CHANGED=true
fi

if detect_changes "microservice-ui" "microservice-ui"; then
    MICROSERVICE_UI_CHANGED=true
fi

echo ""
echo "=== Change Detection Summary ==="
echo "service-registry: $SERVICE_REGISTRY_CHANGED"
echo "api-gateway: $API_GATEWAY_CHANGED"
echo "product-service: $PRODUCT_SERVICE_CHANGED"
echo "offer-service: $OFFER_SERVICE_CHANGED"
echo "microservice-ui: $MICROSERVICE_UI_CHANGED"
echo ""

# Build Service Registry if changed
if [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
    echo "=== Building Service Registry ==="
    cd $APP_BASE/service-registry
    
    echo "Stopping existing service-registry..."
    sudo pkill -f "service-registry" || true
    sleep 5
    
    echo "Building with Maven..."
    mvn clean install -DskipTests
    
    echo "Starting service-registry..."
    nohup mvn spring-boot:run \
        -Dspring-boot.run.jvmArguments="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED" \
        > /tmp/service-registry.log 2>&1 &
    
    wait_for_service "http://localhost:8761/actuator/health" "service-registry" 180
    sleep 5
fi

# Build API Gateway if changed or if service-registry changed
if [ "$API_GATEWAY_CHANGED" = true ] || [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
    echo "=== Building API Gateway ==="
    
    if [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
        echo "Waiting for service registry to be fully ready..."
        sleep 45
    fi
    
    cd $APP_BASE/api-gateway
    
    echo "Stopping existing api-gateway..."
    sudo pkill -f "api-gateway" || true
    sleep 5
    
    echo "Building with Maven..."
    mvn clean install -DskipTests
    
    echo "Starting api-gateway..."
    nohup mvn spring-boot:run \
        -Dspring-boot.run.jvmArguments="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED" \
        > /tmp/api-gateway.log 2>&1 &
    
    wait_for_service "http://localhost:8000/actuator/health" "api-gateway" 90
    sleep 10
fi

# Build Product Service if changed or if service-registry changed
if [ "$PRODUCT_SERVICE_CHANGED" = true ] || [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
    echo "=== Building Product Service ==="
    
    if [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
        echo "Waiting for service registry to be fully ready..."
        sleep 45
    fi
    
    cd $APP_BASE/product-service
    
    echo "Stopping existing product-service..."
    sudo pkill -f "product-service" || true
    sleep 5
    
    echo "Building with Maven..."
    mvn clean install -DskipTests
    
    echo "Starting product-service..."
    nohup mvn spring-boot:run \
        -Dspring-boot.run.jvmArguments="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED" \
        > /tmp/product-service.log 2>&1 &
    
    sleep 10
fi

# Build Offer Service if changed or if service-registry changed
if [ "$OFFER_SERVICE_CHANGED" = true ] || [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
    echo "=== Building Offer Service ==="
    
    if [ "$SERVICE_REGISTRY_CHANGED" = true ]; then
        echo "Waiting for service registry to be fully ready..."
        sleep 45
    fi
    
    cd $APP_BASE/offer-service
    
    echo "Stopping existing offer-service..."
    sudo pkill -f "offer-service" || true
    sleep 5
    
    echo "Building with Maven..."
    mvn clean install -DskipTests
    
    echo "Starting offer-service..."
    nohup mvn spring-boot:run \
        -Dspring-boot.run.jvmArguments="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED" \
        > /tmp/offer-service.log 2>&1 &
    
    sleep 30
fi

# Build Microservice UI if changed or if api-gateway changed
if [ "$MICROSERVICE_UI_CHANGED" = true ] || [ "$API_GATEWAY_CHANGED" = true ]; then
    echo "=== Building Microservice UI ==="
    
    cd $APP_BASE/microservice-ui
    
    echo "Stopping existing microservice-ui..."
    sudo pkill -f "ng serve" || sudo pkill -f "node.*microservice-ui" || true
    sleep 5
    
    echo "Installing dependencies..."
    npm install
    
    echo "Building Angular application..."
    npm run build --prod || npm run build
    
    echo "Starting microservice-ui..."
    nohup npm start > /tmp/microservice-ui.log 2>&1 &
    
    sleep 10
fi

# Health Check
echo ""
echo "=== Health Check ==="
echo "Checking all services..."

services=(
    "http://localhost:8761/actuator/health:Service Registry"
    "http://localhost:8000/actuator/health:API Gateway"
    "http://localhost:8081/actuator/health:Product Service"
    "http://localhost:8082/actuator/health:Offer Service"
    "http://localhost:4200:Microservice UI"
)

for service in "${services[@]}"; do
    IFS=':' read -r url name <<< "$service"
    if curl -s "$url" > /dev/null 2>&1; then
        echo "✅ $name is healthy"
    else
        echo "⚠️  $name is not responding"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Services:"
echo "  - Service Registry: http://localhost:8761"
echo "  - API Gateway: http://localhost:8000"
echo "  - Product Service: http://localhost:8081"
echo "  - Offer Service: http://localhost:8082"
echo "  - Microservice UI: http://localhost:4200"
echo "  - RabbitMQ Management: http://localhost:15672"
echo ""
echo "Logs available at:"
echo "  - Service Registry: /tmp/service-registry.log"
echo "  - API Gateway: /tmp/api-gateway.log"
echo "  - Product Service: /tmp/product-service.log"
echo "  - Offer Service: /tmp/offer-service.log"
echo "  - Microservice UI: /tmp/microservice-ui.log"
echo ""
echo "════════════════════════════════════════════════════════════════"
