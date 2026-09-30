# Resource Consumption Experiment — How to Run It

This guide explains how to bring up the containerized environment used to measure **CPU and memory usage** of Jenkins, GitHub Actions, GitLab CI/CD, and Azure Pipelines runners, as described in `methodology.tex` (Section "Resource Consumption Measurement").

Each tool's runner is isolated inside its own Docker container together with `cAdvisor`, which exports container-level CPU/memory metrics. Prometheus scrapes those metrics, and Grafana visualizes them. The application driving the pipelines is the [Cloud Microservices Application](CLOUD_MICROSERVICES_APP.md) (see the `cloudMicroservices` branch and the `datasets/`, `github/`, `gitlab/`, `azureDevOps/`, `jenkins/` folders at the root of this repository).

This project used [OrbStack](https://orbstack.dev) instead of Docker Desktop on macOS for lower overhead, but any standard Docker Engine + Docker Compose setup works.

## 1. Prerequisites

- Docker (or OrbStack) with Docker Compose.
- A registered runner/agent for whichever tool(s) you want to test — see [RUNNERS_SETUP.md](RUNNERS_SETUP.md) for how to obtain tokens and register each one.
- The [Cloud Microservices Application](CLOUD_MICROSERVICES_APP.md) datasets downloaded into `datasets/` (see [CLOUD_MICROSERVICES_APP.md](CLOUD_MICROSERVICES_APP.md)).

## 2. Start the monitoring stack (Prometheus + Grafana)

```sh
cd prometheus
docker compose -f docker-compose-prometheus.yml up -d
```

This starts:
- **Prometheus** on `http://localhost:9090`, pre-configured (`prometheus/prometheus.yml`) to scrape:
  - `host.docker.internal:8080` — Jenkins' own metrics
  - `host.docker.internal:9102` — GitHub Actions runner's cAdvisor
  - `host.docker.internal:9103` — Jenkins' cAdvisor
  - `host.docker.internal:9104` — GitLab Runner's cAdvisor
  - `host.docker.internal:9105` — Azure Pipelines agent's cAdvisor
- **Grafana** on `http://localhost:3000` (default credentials `admin` / `admin`).

Visit `http://localhost:9090/targets` to confirm the targets are healthy (a target only turns green once the corresponding runner container, below, is up).

## 3. Start each runner container

Each tool lives in its own top-level folder and is started independently with its own Compose file. Only run the ones you need — they are isolated from each other, which is the point of the experiment.

```sh
# GitHub Actions runner (needs REPO_URL and RUNNER_TOKEN, see RUNNERS_SETUP.md)
cd github && docker compose -f docker-compose-github.yml up --build -d

# GitLab Runner (needs GITLAB_URL and GITLAB_REGISTRATION_TOKEN in gitlab/.env)
cd gitlab && docker compose -f docker-compose-gitlab.yml up --build -d

# Azure Pipelines agent (needs AZP_URL, AZP_TOKEN, AZP_POOL)
cd azureDevOps && docker compose -f docker-compose.yml up --build -d

# Jenkins (full server, see RUNNERS_SETUP.md / jenkins/JENKINS.md for the pipeline setup)
cd jenkins && docker compose -f docker-compose-jenkins.yml up --build -d
```

Only start **one runner at a time** if you want to replicate the original methodology, which measured each tool in isolation to avoid cross-tool interference.

## 4. Wire up Grafana

1. Log into Grafana (`http://localhost:3000`).
2. Add a new Prometheus data source with URL `http://prometheus:9090`.
3. Verify connectivity: `docker exec -it grafana ping prometheus`.
4. Import community dashboards by ID:
   - **9964** — Jenkins dashboard
   - **1860** — Node Exporter Full (reused here for container-level CPU/memory panels)

## 5. Trigger pipeline runs

With the target runner container up and registered, push commits (or use the `trigger-runs.sh`/`trigger-runs.ps1` scripts from [execution-time-experiment](execution-time-experiment/README.md), adapted to point at the `cloudMicroservices` application repository) to trigger pipeline executions and observe the corresponding CPU/memory spikes in Grafana.

## 6. Tear down

```sh
docker compose -f <compose-file> down
```

Do **not** remove the `jenkins_home` or `gitlab-runner-config` volumes between runs unless you intend to fully reset those tools — doing so discards all configuration and registered runner credentials.
