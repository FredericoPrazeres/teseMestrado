# Jenkins Microservices Pipeline

This Jenkins setup replicates the GitHub Actions workflow for building and deploying the complete microservices application with intelligent change detection.

## Prerequisites

- Docker and Docker Compose
- ngrok (for GitHub webhook)
- GitHub repository access

## Features

✅ **Intelligent Change Detection**: Only builds services that have changed
✅ **Complete Dependencies**: Maven, Node.js, Java 11/21, RabbitMQ included
✅ **Service Health Monitoring**: Automatic health checks for all services
✅ **cAdvisor Integration**: Container metrics on port 9103
✅ **RabbitMQ**: Message queue for microservices communication

## Quick Start

### 1. Start Jenkins

```bash
cd jenkins
docker-compose -f docker-compose-jenkins.yml up -d
```

Services will be available at:
- Jenkins: http://localhost:8080
- cAdvisor: http://localhost:9103
- RabbitMQ Management: http://localhost:15672

### 2. Configure Jenkins

#### Install Required Plugins

Access Jenkins at http://localhost:8080 and install these plugins:
- **GitHub Integration Plugin**
- **GitHub Plugin**
- **Docker Pipeline Plugin**
- **Pipeline Plugin** (usually pre-installed)

**Note**: Plugin installation may require multiple attempts. Be patient and retry if needed.

#### Create Pipeline Job

1. Create a new **Pipeline** project (not Freestyle) named `microservices-pipeline`
2. Configure the project:
   - **Source Code Management**: Select Git
     - Repository URL: Your GitHub repo URL
     - Credentials: Add GitHub credentials
     - Branch: `applications/complete-microservices`
   - **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
   - **Pipeline**:
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: (same as above)
     - Script Path: `jenkins/Jenkinsfile`

### 3. Setup GitHub Webhook

#### Expose Jenkins with ngrok

```bash
ngrok http http://localhost:8080
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`)

#### Configure Webhook in GitHub

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Configure:
   - **Payload URL**: `https://your-ngrok-url.ngrok-free.app/github-webhook/`
   - **Content Type**: `application/json`
   - **Events**: Select "Just the push event"
   - **Active**: Check this box
4. Save

## How It Works

### Change Detection

The pipeline automatically detects which microservices have changed by comparing commits:

```bash
git diff --name-only HEAD~1 HEAD
```

Services are built only if:
- Their source code has changed
- A dependency service (like service-registry) has changed

### Build Order

1. **Service Registry** (port 8761) - Must start first
2. **API Gateway** (port 8000) - Depends on Service Registry
3. **Product Service** (port 8081) - Depends on Service Registry
4. **Offer Service** (port 8082) - Depends on Service Registry
5. **Microservice UI** (port 4200) - Depends on API Gateway

### Service Dependencies

- **Java 11**: Used for building and running Spring Boot microservices
- **Java 21**: Used for running Jenkins itself
- **Maven 3.8.6**: Build tool for Java services
- **Node.js 12**: Required for Angular UI
- **RabbitMQ**: Message broker for service communication

## Microservices Endpoints

After a successful build:

| Service | URL | Health Check |
|---------|-----|--------------|
| Service Registry | http://localhost:8761 | http://localhost:8761/actuator/health |
| API Gateway | http://localhost:8000 | http://localhost:8000/actuator/health |
| Product Service | http://localhost:8081 | http://localhost:8081/actuator/health |
| Offer Service | http://localhost:8082 | http://localhost:8082/actuator/health |
| Microservice UI | http://localhost:4200 | http://localhost:4200 |
| RabbitMQ Management | http://localhost:15672 | Default: guest/guest |

## Logs

Service logs are available at:
- `/tmp/service-registry.log`
- `/tmp/api-gateway.log`
- `/tmp/product-service.log`
- `/tmp/offer-service.log`
- `/tmp/microservice-ui.log`

View logs from inside the container:
```bash
docker exec -it jenkins_service tail -f /tmp/service-registry.log
```

## Troubleshooting

### Services Not Starting

Check individual service logs:
```bash
docker exec -it jenkins_service bash
tail -f /tmp/service-registry.log
```

### RabbitMQ Issues

Verify RabbitMQ is running:
```bash
docker exec -it jenkins_service sudo rabbitmqctl status
```

### Maven Build Failures

Ensure Java 11 is being used:
```bash
docker exec -it jenkins_service bash
echo $JAVA_HOME
java -version
```

### Port Conflicts

If ports are already in use, stop existing services:
```bash
docker exec -it jenkins_service sudo pkill -f "spring-boot"
docker exec -it jenkins_service sudo pkill -f "ng serve"
```

## Manual Pipeline Execution

You can manually trigger the pipeline script:

```bash
docker exec -it jenkins_service bash
export WORKSPACE=/var/jenkins_home/workspace/microservices-pipeline
export GIT_COMMIT=$(git rev-parse HEAD)
export GIT_PREVIOUS_COMMIT=$(git rev-parse HEAD~1)
bash /home/scripts/pipeline.sh
```

## Important Notes

⚠️ **Volume Persistence**: Do not delete Docker volumes (`jenkins_home`) as this will lose all Jenkins configurations and build history.

⚠️ **First Build**: The first build will take longer as it builds all services from scratch.

⚠️ **Resource Usage**: Ensure your system has adequate resources (at least 4GB RAM recommended).

## Architecture Comparison

This Jenkins setup mirrors the GitHub Actions workflow (`main.yml`) with the following structure:

| GitHub Actions | Jenkins Equivalent |
|----------------|-------------------|
| `detect-changes` job | Change detection in `pipeline.sh` |
| `setup-infrastructure` job | RabbitMQ setup in `start.sh` |
| Individual build jobs | Sequential builds in `pipeline.sh` |
| `health-check` job | Health check stage in `Jenkinsfile` |

## Monitoring

- **cAdvisor**: Container metrics available at http://localhost:9103/metrics
- **Jenkins**: Build history and logs in Jenkins UI
- **Service Health**: Automatic health checks after each deployment
    