# Execution Time Experiment — Replication Materials

This folder contains the pipeline definitions and helper scripts used to measure **pipeline execution time** across four CI/CD tools — GitHub Actions, GitLab CI/CD, Azure Pipelines, and Jenkins (Section "Execution Time Measurement").

Unlike the [resource consumption experiment](../RESOURCE_CONSUMPTION_EXPERIMENT.md), these pipelines were executed with **natively installed, self-hosted runners** on three host machines (macOS, Windows, Linux), not inside containers.

Each application originally lived in its own git branch (`applications/<name>`). The files below were extracted from those branches and consolidated here so they can be inspected/reused without checking out every branch. The original branches still exist in the repository (`applications/directus`, `applications/tooljet`, `applications/calcom`, `applications/home-assistant-core`, `applications/outline`) if you need full application source code alongside the pipeline files.

The GitHub Actions, Azure Pipelines, and Jenkins files come from the GitHub-hosted repository (this repository). The GitLab CI/CD files come from a **separate GitLab-hosted mirror** of the same application branches (per the methodology, GitLab pipelines were configured directly on GitLab, not on GitHub) — they were extracted from a local clone of that GitLab repository and copied in here for convenience.

## Folder layout

```
execution-time-experiment/
  <application>/
    github/       # GitHub Actions workflow files (.github/workflows/*.yml in the original branch)
    azure/        # Azure Pipelines definitions (azureDevOps/*.yml in the original branch)
    gitlab/       # GitLab CI/CD definitions (.gitlab-ci.yml and OS-specific variants, from the GitLab-hosted mirror)
    jenkins/      # Jenkinsfile used by the Jenkins pipeline job
    trigger-runs.sh   # Bash script to trigger N pipeline runs via empty commits (macOS/Linux)
    trigger-runs.ps1  # PowerShell equivalent (Windows), where it was used
```

## What exists per application

The five applications were adapted iteratively, so not every application has the exact same set of variants. The table below documents exactly what is present for each one — use it as a map before you start reusing/extending these pipelines.

| Application | GitHub Actions files | Azure Pipelines files | Jenkins | GitLab CI/CD files |
|---|---|---|---|---|
| **directus** | `main.yml` (single-job / "steps" config, Linux+macOS), `windows.yml` (multi-job, Windows, PowerShell), `windowsSteps.yml` (single-job, Windows, PowerShell) | `azure-pipelines.yml` (single-job config) | `Jenkinsfile` | `.gitlab-ci.yml` (single-job/steps config, `docker`+`linux` tags) |
| **tooljet** | `main.yml` (multi-job, Linux+macOS) | `azure-pipelines.yml` (baseline), `azure-pipelines-jobs.yml` (multi-job), `azure-pipelines-steps.yml` (single-job) | `Jenkinsfile` | `.gitlab-ci.yml` (single-job/steps config, `linux`+`docker` tags) |
| **calcom** | `main.yml` (multi-job, "Job Overhead Benchmark"), `jobs-benchmark.yml` (multi-job variant), `steps-benchmark.yml` (single-job, "Step Overhead Benchmark") | `azure-pipelines.yml` (baseline), `azure-pipelines-jobs.yml`, `azure-pipelines-steps.yml` | `Jenkinsfile` | `.gitlab-ci.yml` (single-job/steps config, `windows`+`shell` tags, PowerShell) |
| **home-assistant-core** | `main.yml` (multi-job, Linux+macOS only — no Windows variant was created) | `azure-pipelines.yml` (single-job config) | `Jenkinsfile` | `.gitlab-ci.yml` (single-job/steps config, `docker`+`linux` tags) |
| **outline** | `main.yml` (multi-job, Linux+macOS), `outline.yml` (multi-job, Windows), `outline-steps.yml` (single-job, Windows) | `azure-pipelines.yml`, `azure-pipelines-outline.yml`, `azure-pipelines-outline-windows.yml` | `Jenkinsfile`, and a `pipeline-outline.sh` helper script (see the `applications/outline` branch) | `.gitlab-ci.yml` (multi-job, 10 stages, `docker`+`linux` tags — matches the 10-job pipeline), plus `.gitlab-ci-outline.yml` and `.gitlab-ci-outline-windows.yml` (an earlier/reduced 6-stage variant, Linux and Windows respectively) |

Notes:
- "Multi-job" corresponds to the pipeline design in the methodology where every logical operation (checkout, install, lint, build, test, ...) is its own job/stage. "Single-job" (a.k.a. "steps") groups the same operations as sequential steps inside one job.
- macOS and Linux share the same GitHub Actions/Azure Pipelines YAML files because both execute steps through a POSIX shell (`bash`) via `runs-on: self-hosted` without an OS-specific label; only the machine registered against that runner pool changes. Windows needed dedicated files because steps had to run under `powershell`.
- `jenkins/pipeline.sh`, found at the root of some of the original `applications/*` GitHub branches, was an **empty leftover from the resource-consumption experiment template** and was intentionally **not** copied here — the real Jenkins pipeline lives in the `Jenkinsfile`.
- Each application's GitLab CI/CD pipeline lived in a single `.gitlab-ci.yml` file that was repeatedly edited in place as the experiment iterated between the multi-job and single-job configurations (visible in that repository's commit history, e.g. commit messages like "Test job" / "Let's switch to steps"). Only the final state committed to each branch could be recovered; it is **not** guaranteed to represent every OS/config combination actually measured — `outline` is the only application where an additional job-config variant survived as separate files.
- GitLab jobs rely on **runner tags** (e.g. `docker`+`linux`, `windows`, `shell`) instead of an OS-specific `runs-on:` label — make sure the tags in `default.tags:` match the tags your own runner was registered/configured with (see [RUNNERS_SETUP.md](../RUNNERS_SETUP.md)).
- For jobs/stages that need the workspace/artifacts from a previous job (GitLab wipes the workspace by default), set `variables: { GIT_STRATEGY: none }` on the dependent jobs, as done in the original pipelines.

## Reusing these pipelines

1. Pick an application folder and check out the corresponding `applications/<name>` branch to get the full application source alongside these pipeline files.
2. Install a self-hosted runner/agent for the tool you want to test (see [RUNNERS_SETUP.md](../RUNNERS_SETUP.md)).
3. Copy the relevant file to the location the tool expects (e.g. `github/main.yml` → `.github/workflows/main.yml`, `azure/azure-pipelines.yml` → repo root, `gitlab/.gitlab-ci.yml` → repo root on your GitLab-hosted mirror, `jenkins/Jenkinsfile` → repo root or a Jenkins pipeline job configuration).
4. Push to the branch referenced in the workflow's trigger (check the `branches:` / `trigger:` section of each file — some still reference the original throwaway branch names used during the experiment, e.g. `applications/directuss`; update them to match your own branch).
5. Use `trigger-runs.sh` (macOS/Linux) or `trigger-runs.ps1` (Windows) to automatically push a configurable number of empty commits at a configurable interval, to collect multiple runs:
   ```sh
   ./trigger-runs.sh 5 240     # 5 runs, 240 seconds apart
   ```
