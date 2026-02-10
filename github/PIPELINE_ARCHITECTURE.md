# GitHub Actions CI/CD Pipeline Architecture

## Pipeline Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                          │
│                    (Push to master / Pull Request)                 │
└─────────────────────────────┬──────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                    Self-Hosted GitHub Runner                       │
│                      (Running in Docker)                           │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Stage 1: Setup & Validate                       │ │
│  │  • Checkout code                                             │ │
│  │  • Validate composer.json                                    │ │
│  │  • Check PHP version and extensions                          │ │
│  └────────────────────────┬─────────────────────────────────────┘ │
│                           │                                        │
│                           ▼                                        │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │            Stage 2: Install Dependencies                     │ │
│  │  ┌────────────────────┐  ┌─────────────────────┐             │ │
│  │  │  Composer          │  │    NPM              │             │ │
│  │  │  • Cache restore   │  │    • Cache restore  │             │ │
│  │  │  • composer install│  │    • npm ci         │             │ │
│  │  │  • Cache save      │  │    • npm run prod   │             │ │
│  │  └────────────────────┘  └─────────────────────┘             │ │
│  └────────────────────────┬─────────────────────────────────────┘ │
│                           │                                        │
│              ┌────────────┴────────────┬─────────────────┐        │
│              ▼                         ▼                 ▼        │
│  ┌──────────────────┐    ┌──────────────────┐  ┌────────────────┐│
│  │ Stage 3:         │    │  Stage 4:        │  │  Stage 5:      ││
│  │ Code Quality     │    │  Testing         │  │  Security      ││
│  │                  │    │                  │  │                ││
│  │ • PSR-12 Style   │    │ • Prepare .env   │  │ • composer     ││
│  │ • Static         │    │ • Generate key   │  │   audit        ││
│  │   Analysis       │    │ • Create SQLite  │  │ • Check known  ││
│  │ • Code Quality   │    │ • Unit Tests     │  │   CVEs         ││
│  │   Metrics        │    │ • Feature Tests  │  │                ││
│  │                  │    │ • Upload Reports │  │                ││
│  └──────────────────┘    └──────────────────┘  └────────────────┘│
│              │                     │                     │         │
│              └─────────────────────┴─────────────────────┘         │
│                                    │                               │
│                                    ▼                               │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │               Stage 6: Build Report                          │ │
│  │  • Generate summary                                          │ │
│  │  • Compile metrics                                           │ │
│  │  • Send notifications                                        │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Container Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Host                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │          GitHub Runner Container                           │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ GitHub Actions Runner Agent                          │ │ │
│  │  │ • Listens for workflow jobs                          │ │ │
│  │  │ • Executes pipeline steps                            │ │ │
│  │  │ • Reports status back to GitHub                      │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ Development Environment                              │ │ │
│  │  │ • PHP 8.1 + Extensions                               │ │ │
│  │  │ • Composer 2.x                                       │ │ │
│  │  │ • Node.js 18.x + npm                                 │ │ │
│  │  │ • Docker CLI                                         │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ cAdvisor (Port 8080)                                 │ │ │
│  │  │ • Container metrics                                  │ │ │
│  │  │ • Resource monitoring                                │ │ │
│  │  │ • Prometheus endpoints                               │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ Volumes                                              │ │ │
│  │  │ • /home/runner/_work (workspace)                     │ │ │
│  │  │ • /var/run/docker.sock (Docker socket)               │ │ │
│  │  │ • Akaunting source code (mounted)                    │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────┬───────────────────────────────┘ │
│                               │                                 │
│                               │ Network: monitoring             │
│                               │                                 │
│  ┌────────────────────────────┴───────────────────────────────┐ │
│  │          MySQL 8.0 Container                               │ │
│  │                                                            │ │
│  │  • Database: akaunting                                     │ │
│  │  • Port: 3306 (internal) / 3307 (external)                │ │
│  │  • Health checks enabled                                   │ │
│  │  • Persistent volume: mysql-data                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │                             │
         │                             │
         ▼                             ▼
  Port 9102 (cAdvisor)          Port 3307 (MySQL)
```

## Data Flow

```
┌──────────┐         ┌──────────┐         ┌──────────┐
│          │  Push/  │          │  Picks  │          │
│ Developer│  ──────→│  GitHub  │  ──────→│  Runner  │
│          │   PR    │          │   Job   │          │
└──────────┘         └──────────┘         └─────┬────┘
                                                 │
                                                 │ Executes
                                                 ▼
                     ┌────────────────────────────────────────┐
                     │        Akaunting Application           │
                     │                                        │
                     │  1. Install dependencies               │
                     │     ├─ composer install                │
                     │     └─ npm ci && npm run prod          │
                     │                                        │
                     │  2. Quality checks                     │
                     │     ├─ Code style (PSR-12)             │
                     │     └─ Static analysis                 │
                     │                                        │
                     │  3. Testing                            │
                     │     ├─ Setup test environment          │
                     │     ├─ Run unit tests                  │
                     │     └─ Run feature tests               │
                     │                                        │
                     │  4. Security                           │
                     │     └─ composer audit                  │
                     │                                        │
                     └─────────────────┬──────────────────────┘
                                       │
                                       │ Reports
                                       ▼
                     ┌────────────────────────────────────────┐
                     │           Test Results                 │
                     │                                        │
                     │  • JUnit XML reports                   │
                     │  • Code coverage                       │
                     │  • Build artifacts                     │
                     │  • Security vulnerabilities            │
                     └────────────────┬───────────────────────┘
                                      │
                                      │ Upload
                                      ▼
                     ┌────────────────────────────────────────┐
                     │      GitHub Actions Artifacts          │
                     │                                        │
                     │  Available for download and analysis   │
                     └────────────────────────────────────────┘
```

## Caching Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                        First Build                             │
│                                                                │
│  1. Install Dependencies (SLOW)                                │
│     ├─ Download all Composer packages    [~2-3 min]           │
│     ├─ Download all npm packages         [~1-2 min]           │
│     └─ Build frontend assets             [~1-2 min]           │
│                                                                │
│  2. Save to Cache                                              │
│     ├─ Cache Composer packages by composer.lock hash          │
│     └─ Cache node_modules by package-lock.json hash           │
│                                                                │
│  Total Time: ~5-7 minutes                                      │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    Subsequent Builds                           │
│                                                                │
│  1. Restore from Cache (FAST)                                  │
│     ├─ Restore Composer packages         [~10-20 sec]         │
│     └─ Restore node_modules              [~10-20 sec]         │
│                                                                │
│  2. Install only if cache miss                                 │
│     └─ Only runs if dependencies changed                       │
│                                                                │
│  Total Time: ~30-60 seconds (if cache hit)                     │
└────────────────────────────────────────────────────────────────┘

Cache Key Format:
┌──────────────────────────────────────────────────────────────┐
│ ${{ runner.os }}-composer-${{ hashFiles('composer.lock') }}  │
│                                                              │
│ Example: Linux-composer-a3f5e8b9c1d2...                      │
└──────────────────────────────────────────────────────────────┘
```

## Parallel Execution

```
Time ──────────────────────────────────────────────────────────→

Stage 1: Setup & Validate
├─────────┤
          │
          └──→ Stage 2: Install Dependencies
               ├────────────────────┤
                                    │
                                    └──→ Stage 3, 4, 5 (Parallel)
                                         ├──────────┤ Code Quality
                                         ├──────────┤ Testing
                                         ├──────────┤ Security
                                                    │
                                                    └──→ Stage 6: Report
                                                         ├───┤

Total Time (with parallel): ~3-5 minutes (with cache)
Total Time (sequential):    ~6-9 minutes (with cache)

Speedup: ~40-50% reduction in pipeline time
```

## Monitoring Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      cAdvisor                                   │
│                                                                 │
│  Collects Metrics:                                              │
│  ├─ CPU Usage (per container)                                   │
│  ├─ Memory Usage (per container)                                │
│  ├─ Disk I/O                                                    │
│  ├─ Network Traffic                                             │
│  └─ Container Lifecycle Events                                  │
│                                                                 │
│  Exposes:                                                       │
│  ├─ Web UI: http://localhost:9102                               │
│  └─ Prometheus Metrics: http://localhost:9102/metrics           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Can be scraped by
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Prometheus (Optional)                      │
│                                                                 │
│  • Stores time-series metrics                                   │
│  • Enables alerting                                             │
│  • Provides query language                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Visualized by
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Grafana (Optional)                        │
│                                                                 │
│  • Creates dashboards                                           │
│  • Visualizes trends                                            │
│  • Sends alerts                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Security Scanning Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Security Scan Job                         │
│                                                              │
│  1. Composer Audit                                           │
│     ├─ Checks PHP dependencies                               │
│     ├─ Queries security advisories database                  │
│     └─ Reports known CVEs                                    │
│                                                              │
│  2. NPM Audit (can be added)                                 │
│     ├─ Checks Node.js dependencies                           │
│     ├─ Queries npm security database                         │
│     └─ Reports vulnerabilities                               │
│                                                              │
│  3. Future Enhancements                                      │
│     ├─ SAST (Static Application Security Testing)            │
│     ├─ Dependency license checking                           │
│     └─ Container image scanning                              │
│                                                              │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ If vulnerabilities found
                         ▼
        ┌────────────────────────────────────┐
        │  Report to GitHub Security Tab     │
        │  and fail the build                │
        └────────────────────────────────────┘
```

## Resource Allocation

```
┌──────────────────────────────────────────────────────────────┐
│                    Container Resources                        │
│                                                              │
│  GitHub Runner:                                              │
│  ├─ CPU: 2-4 cores (recommended)                             │
│  ├─ Memory: 4-8 GB (recommended)                             │
│  └─ Disk: 20-50 GB (workspace + cache)                       │
│                                                              │
│  MySQL:                                                      │
│  ├─ CPU: 1-2 cores                                           │
│  ├─ Memory: 1-2 GB                                           │
│  └─ Disk: 5-10 GB                                            │
│                                                              │
│  cAdvisor:                                                   │
│  ├─ CPU: 0.5 cores                                           │
│  ├─ Memory: 200-500 MB                                       │
│  └─ Disk: Negligible                                         │
│                                                              │
│  Total Recommended:                                          │
│  ├─ CPU: 4-7 cores                                           │
│  ├─ Memory: 6-11 GB                                          │
│  └─ Disk: 30-70 GB                                           │
└──────────────────────────────────────────────────────────────┘
```

## Legend

```
├─  Branch/Child element
└─  Last branch element
│   Continuation
─→  Flow direction
▼   Downward flow
├──────┤  Time duration bar
```
