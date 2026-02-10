# GitHub Actions Self-Hosted Runner for Akaunting

This Docker container runs a GitHub Actions self-hosted runner with all the necessary dependencies to build and test the Akaunting application.

## Prerequisites

- Docker and Docker Compose installed
- GitHub repository access
- GitHub Personal Access Token or Runner Token

## Features

- **PHP 8.1** with all required extensions for Akaunting
- **Composer** for PHP dependency management
- **Node.js 18.x** and npm for frontend assets
- **MySQL 8.0** database for testing
- **Docker CLI** for container operations within the runner
- **cAdvisor** for container monitoring

## Setup

1. **Get your GitHub Runner Token:**
   - Go to your repository settings
   - Navigate to Actions → Runners
   - Click "New self-hosted runner"
   - Copy the token provided

2. **Create a `.env` file:**
   ```bash
   cp .env.example .env
   ```

3. **Configure environment variables in `.env`:**
   ```env
   REPO_URL=https://github.com/YOUR_USERNAME/YOUR_REPO
   RUNNER_TOKEN=YOUR_RUNNER_TOKEN_HERE
   ```

4. **Build and start the runner:**
   ```bash
   docker-compose -f docker-compose-github.yml build
   docker-compose -f docker-compose-github.yml up -d
   ```

5. **Verify the runner is connected:**
   - Go to your repository settings → Actions → Runners
   - You should see your runner listed and in "Idle" status

## Pipeline Features

The GitHub Actions pipeline (`main.yml`) includes:

### 1. **Setup and Validate**
   - Checks out the code
   - Validates `composer.json`
   - Verifies PHP installation and extensions

### 2. **Install Dependencies**
   - Caches Composer dependencies
   - Installs PHP packages with Composer
   - Caches Node.js modules
   - Installs npm packages
   - Builds production frontend assets

### 3. **Code Quality Checks**
   - Code style validation (PSR-12)
   - Static analysis
   - Code quality metrics

### 4. **Testing**
   - Prepares Laravel application
   - Runs Unit tests
   - Runs Feature tests
   - Generates test reports
   - Uploads test artifacts

### 5. **Security Scan**
   - Checks for known vulnerabilities in dependencies
   - Runs Composer audit

### 6. **Build Report**
   - Generates comprehensive build report
   - Notifies on completion

## Monitoring

- **cAdvisor** is accessible at `http://localhost:9102`
- Monitor container resources and performance
- View metrics in Prometheus format at `/metrics`

## Database Access

MySQL is available for testing:
- **Host:** localhost (from host machine) or mysql (from runner)
- **Port:** 3307 (external), 3306 (internal)
- **Database:** akaunting
- **User:** akaunting
- **Password:** akaunting_password
- **Root Password:** root_password

## Logs

View runner logs:
```bash
docker-compose -f docker-compose-github.yml logs -f github-runner
```

View MySQL logs:
```bash
docker-compose -f docker-compose-github.yml logs -f mysql
```

## Troubleshooting

### Runner not connecting
- Verify the `REPO_URL` is correct
- Ensure the `RUNNER_TOKEN` is valid (tokens expire after 1 hour)
- Check runner logs for errors

### Permission issues
- Ensure Docker socket has correct permissions
- The runner user needs to be in the docker group

### Tests failing
- Check if MySQL is healthy: `docker-compose -f docker-compose-github.yml ps`
- Verify PHP extensions are installed: `php -m`
- Ensure `.env` file exists in akaunting directory

## Stopping the Runner

```bash
docker-compose -f docker-compose-github.yml down
```

To remove volumes as well:
```bash
docker-compose -f docker-compose-github.yml down -v
```

## Architecture

```
┌─────────────────────────────────────┐
│   GitHub Actions Runner Container   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   GitHub Actions Runner      │  │
│  │   - PHP 8.1 + Extensions    │  │
│  │   - Composer                │  │
│  │   - Node.js 18.x + npm      │  │
│  │   - Docker CLI              │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   cAdvisor (Monitoring)      │  │
│  │   Port: 8080                │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
            │
            │ Network: monitoring
            │
┌─────────────────────────────────────┐
│     MySQL 8.0 Container             │
│                                     │
│  Database: akaunting                │
│  Port: 3306 (internal)              │
│        3307 (external)              │
└─────────────────────────────────────┘
```

## Additional Commands

### Run tests manually in the runner:
```bash
docker exec -it github-runner bash
cd /home/runner/_work/YOUR_REPO/YOUR_REPO/akaunting
./vendor/bin/phpunit
```

### Access MySQL:
```bash
docker exec -it github-mysql mysql -u akaunting -pakaunting_password akaunting
```

### Rebuild the runner:
```bash
docker-compose -f docker-compose-github.yml build --no-cache
docker-compose -f docker-compose-github.yml up -d
```
