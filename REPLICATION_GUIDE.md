# Replication Package Guide

This repository is the replication package for the thesis experiments comparing four CI/CD tools — **GitHub Actions**, **GitLab CI/CD**, **Azure Pipelines**, and **Jenkins** — across two dimensions: resource consumption and execution time.

## Two experiments, two setups

| | Resource Consumption | Execution Time |
|---|---|---|
| **Goal** | CPU/memory usage per runner | Pipeline execution duration |
| **Isolation** | Each runner inside its own Docker container | Runners installed natively on the host OS |
| **Application under test** | [Cloud Microservices Application](CLOUD_MICROSERVICES_APP.md) (`cloudMicroservices` branch) | 5 production-grade apps, one branch each (see below) |
| **Where to start** | [RESOURCE_CONSUMPTION_EXPERIMENT.md](RESOURCE_CONSUMPTION_EXPERIMENT.md) | [execution-time-experiment/README.md](execution-time-experiment/README.md) |

Both experiments reuse the same runner-registration mechanics, documented once in [RUNNERS_SETUP.md](RUNNERS_SETUP.md).

## Repository map

```
README.md                              # Repository overview, points to this guide
CLOUD_MICROSERVICES_APP.md             # Cloud Microservices Application: dataset download & usage
RUNNERS_SETUP.md                       # How to register/install a runner for each of the 4 tools
RESOURCE_CONSUMPTION_EXPERIMENT.md     # How to run the containerized runner + Prometheus/Grafana stack
dockerConfig.md                        # Docker socket permission fix needed on some Linux hosts
azureDevOpsMemory.csv                  # Raw memory measurements collected for Azure Pipelines

datasets/                              # Datasets used by the Cloud Microservices Application
azureDevOps/ github/ gitlab/ jenkins/  # Per-tool Dockerfile + Compose files for the containerized
                                        # (resource consumption) runners
prometheus/                            # Prometheus + Grafana Compose stack and scrape config

execution-time-experiment/             # Consolidated pipeline files for the execution-time experiment,
                                        # extracted from the applications/* branches (see its own README)
```

The `gitlab/` folder inside each `execution-time-experiment/<application>/` was sourced from a **separate GitLab-hosted mirror repository** (`teseMestradoGitlab` on gitlab.com), not from this GitHub repository — see the note in [execution-time-experiment/README.md](execution-time-experiment/README.md).

## Branches

| Branch | Purpose |
|---|---|
| `cloudMicroservices` | Source for the resource-consumption experiment's target application (mirrors the top-level `azureDevOps/`, `github/`, `gitlab/`, `jenkins/`, `prometheus/`, `datasets/` folders on `master`) |
| `applications/directus`, `applications/tooljet`, `applications/calcom`, `applications/home-assistant-core`, `applications/outline` | Each holds one execution-time-experiment application: full app source plus its GitHub Actions/Azure Pipelines/Jenkins pipeline files. Pipeline files were extracted into [execution-time-experiment/](execution-time-experiment/README.md) on `master` for convenience. The equivalent branches on the separate GitLab-hosted mirror hold the GitLab CI/CD pipeline (`.gitlab-ci.yml`) for each application |

## Suggested reading order for a new researcher

1. Read [RUNNERS_SETUP.md](RUNNERS_SETUP.md) to understand how each tool's runner/agent is registered.
2. To replicate **resource consumption** measurements, follow [RESOURCE_CONSUMPTION_EXPERIMENT.md](RESOURCE_CONSUMPTION_EXPERIMENT.md).
3. To replicate **execution time** measurements, follow [execution-time-experiment/README.md](execution-time-experiment/README.md).
