# Akaunting CI/CD Setup Summary

## What Was Done

### 1. Updated GitHub Runner Dockerfile (`github/Dockerfile`)
The Dockerfile has been enhanced to support the Akaunting Laravel application:

**Added Components:**
- **PHP 8.1** with all required extensions:
  - php8.1-cli, php8.1-fpm
  - php8.1-mysql, php8.1-pgsql, php8.1-sqlite3
  - php8.1-zip, php8.1-gd, php8.1-mbstring
  - php8.1-curl, php8.1-xml, php8.1-bcmath
  - php8.1-intl, php8.1-tokenizer, php8.1-dom, php8.1-fileinfo
  
- **Composer** - PHP dependency manager
- **Node.js 18.x** and npm - For frontend asset compilation
- **Docker CLI** - To run Docker commands inside the runner
- **cAdvisor** - Container monitoring

### 2. Updated Start Script (`github/start.sh`)
Enhanced the startup script with:
- Better error handling with conditional checks
- Improved Docker socket permission management
- Safe directory ownership setup

### 3. Enhanced Docker Compose (`github/docker-compose-github.yml`)
Added:
- **MySQL 8.0 service** for database testing
- Volume mounting for the Akaunting application
- Health checks for MySQL
- Proper networking between services
- Exposed ports for external access

### 4. Created Comprehensive CI/CD Pipeline (`.github/workflows/main.yml`)
A multi-stage pipeline with the following jobs:

#### **Job 1: Setup and Validate**
- Checks out code
- Validates composer.json structure
- Verifies PHP version and extensions

#### **Job 2: Install Dependencies**
- Caches Composer dependencies for faster builds
- Installs PHP packages
- Caches Node modules
- Installs npm packages
- Builds production frontend assets

#### **Job 3: Code Quality Checks**
- Validates PSR-12 code style compliance
- Runs static analysis (placeholder for PHPStan/Psalm)
- Can be extended with additional quality tools

#### **Job 4: Run Tests**
- Prepares Laravel application (.env, keys, database)
- Runs Unit tests
- Runs Feature tests
- Generates JUnit XML reports
- Uploads test artifacts

#### **Job 5: Security Scan**
- Checks for known security vulnerabilities
- Runs composer audit on dependencies

#### **Job 6: Build Report**
- Generates comprehensive build summary
- Reports pipeline status
- Notifies on completion

### 5. Documentation
Created comprehensive documentation:
- **github/README.md** - Complete setup guide
- **github/.env.example** - Environment configuration template

## How to Use

### Initial Setup

1. **Navigate to the GitHub folder:**
   ```bash
   cd github
   ```

2. **Create environment configuration:**
   ```bash
   cp .env.example .env
   ```

3. **Edit `.env` with your values:**
   ```env
   REPO_URL=https://github.com/YOUR_USERNAME/teseMestrado
   RUNNER_TOKEN=YOUR_GITHUB_RUNNER_TOKEN
   ```

4. **Get GitHub Runner Token:**
   - Go to: Repository → Settings → Actions → Runners
   - Click "New self-hosted runner"
   - Copy the token provided

5. **Build and start the containers:**
   ```bash
   docker-compose -f docker-compose-github.yml build
   docker-compose -f docker-compose-github.yml up -d
   ```

6. **Verify runner connection:**
   - Check repository Settings → Actions → Runners
   - Runner should appear as "Idle"

### Running the Pipeline

The pipeline automatically triggers on:
- Push to `master` branch
- Pull requests to `master` branch

To manually trigger:
1. Make any change and commit
2. Push to master: `git push origin master`
3. Watch the pipeline in the "Actions" tab

### Monitoring

- **cAdvisor Dashboard:** http://localhost:9102
- **Runner Logs:** `docker-compose -f docker-compose-github.yml logs -f github-runner`
- **MySQL Logs:** `docker-compose -f docker-compose-github.yml logs -f mysql`

### Database Access

For debugging tests:
```bash
# From host
mysql -h 127.0.0.1 -P 3307 -u akaunting -pakaunting_password akaunting

# From container
docker exec -it github-mysql mysql -u akaunting -pakaunting_password akaunting
```

## Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Trigger (Push/PR)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Job 1: Setup and Validate                      │
│  • Checkout code                                            │
│  • Validate composer.json                                   │
│  • Check PHP version                                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           Job 2: Install Dependencies                       │
│  • Cache Composer deps                                      │
│  • Install PHP packages                                     │
│  • Cache Node modules                                       │
│  • Install npm packages                                     │
│  • Build frontend assets                                    │
└────────────────────────┬────────────────────────────────────┘
                         │
            ┌────────────┴────────────┬─────────────────┐
            ▼                         ▼                 ▼
┌──────────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Job 3: Code Quality  │  │  Job 4: Tests    │  │ Job 5: Security  │
│ • PSR-12 style       │  │  • Prepare app   │  │ • Composer audit │
│ • Static analysis    │  │  • Unit tests    │  │ • Vuln. check    │
└──────────────────────┘  │  • Feature tests │  └──────────────────┘
                          │  • Upload reports│
                          └──────────────────┘
                                    │
            ┌───────────────────────┴────────────────────┐
            ▼                                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Job 6: Build Report                             │
│  • Generate summary                                          │
│  • Notify completion                                         │
└──────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. **Caching Strategy**
- Composer dependencies cached by `composer.lock` hash
- Node modules cached by `package-lock.json` hash
- Significantly reduces build time on subsequent runs

### 2. **Parallel Execution**
- Code quality, tests, and security scans run in parallel
- Maximizes runner efficiency
- Reduces total pipeline time

### 3. **Test Reporting**
- JUnit XML format for test results
- Separate reports for Unit and Feature tests
- Artifacts uploaded for later analysis
- Test results available even if tests fail

### 4. **Database Support**
- MySQL 8.0 container for integration tests
- Health checks ensure database is ready
- Persistent volumes for data retention
- Easy access for debugging

### 5. **Monitoring**
- cAdvisor provides container metrics
- Prometheus-compatible endpoints
- Resource usage tracking
- Performance monitoring

## Extending the Pipeline

### Add Code Style Checker
Uncomment and configure in the Code Quality job:
```yaml
- name: Check code style (PSR-12)
  working-directory: ./akaunting
  run: |
    composer require --dev squizlabs/php_codesniffer
    ./vendor/bin/phpcs --standard=PSR12 app/
```

### Add Static Analysis
Uncomment and configure:
```yaml
- name: Run static analysis
  working-directory: ./akaunting
  run: |
    composer require --dev phpstan/phpstan
    ./vendor/bin/phpstan analyse --level=5 app/
```

### Add Code Coverage
```yaml
- name: Run tests with coverage
  working-directory: ./akaunting
  run: |
    ./vendor/bin/phpunit --coverage-html coverage/ --coverage-clover coverage.xml
    
- name: Upload coverage
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: akaunting/coverage/
```

### Add Deployment Job
```yaml
deploy:
  name: Deploy to Production
  runs-on: self-hosted
  needs: [code-quality, test, security-scan]
  if: github.ref == 'refs/heads/master'
  steps:
    - name: Deploy
      run: |
        # Add deployment commands here
        echo "Deploying to production..."
```

## Troubleshooting

### Common Issues

**Issue: Runner not connecting**
- Solution: Check REPO_URL format and regenerate RUNNER_TOKEN

**Issue: Tests failing - database connection**
- Solution: Verify MySQL is healthy: `docker-compose ps`
- Check database credentials in .env

**Issue: Permission denied errors**
- Solution: Ensure Docker socket permissions are correct
- Runner user must be in docker group

**Issue: Frontend build failing**
- Solution: Clear node_modules and npm cache
- Rebuild container: `docker-compose build --no-cache`

**Issue: Out of disk space**
- Solution: Clean Docker: `docker system prune -a --volumes`
- Remove old runner data: `docker volume rm github_runner-data`

## Next Steps

For your thesis, you can now:

1. **Compare with Azure DevOps and Jenkins:**
   - Apply similar changes to `azureDevOps/` and `jenkins/` folders
   - Compare pipeline execution times
   - Analyze resource usage via cAdvisor

2. **Metrics Collection:**
   - Monitor build times for each job
   - Track resource consumption (CPU, memory, disk)
   - Compare caching efficiency

3. **Performance Analysis:**
   - Measure parallel vs sequential execution
   - Evaluate caching impact on build speed
   - Compare runner startup times

4. **Documentation:**
   - Document differences between CI/CD platforms
   - Create comparison matrices
   - Generate performance graphs

## Files Modified/Created

- ✅ `github/Dockerfile` - Updated with PHP, Composer, Node.js, Docker CLI
- ✅ `github/start.sh` - Enhanced startup script
- ✅ `github/docker-compose-github.yml` - Added MySQL and volumes
- ✅ `.github/workflows/main.yml` - Comprehensive CI/CD pipeline
- ✅ `github/README.md` - Complete documentation
- ✅ `github/.env.example` - Environment template
- ✅ `github/SETUP_SUMMARY.md` - This file

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Akaunting Documentation](https://akaunting.com/hc/docs)
- [Laravel Testing](https://laravel.com/docs/testing)
- [Docker Compose Reference](https://docs.docker.com/compose/)
