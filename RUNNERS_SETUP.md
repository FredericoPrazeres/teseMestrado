# Setting Up the Runners

This guide explains how to set up a self-hosted runner/agent for each of the four CI/CD tools studied in this project. It covers two contexts:

- **Containerized runners** (used for the [resource consumption experiment](RESOURCE_CONSUMPTION_EXPERIMENT.md)) — the runner agent is installed *inside* a Docker container, as automated by the `Dockerfile`/`start.sh` pair in each tool's top-level folder (`github/`, `gitlab/`, `azureDevOps/`, `jenkins/`).
- **Native runners** (used for the [execution time experiment](execution-time-experiment/README.md)) — the runner agent is installed directly on the host OS (macOS, Windows, or Linux).

In both cases the underlying registration steps are the same; only *where* the agent process runs changes.

## 1. GitHub Actions

1. In the target GitHub repository, go to **Settings → Actions → Runners → New self-hosted runner** and generate a registration token, or generate one via the API/CLI.
2. **Containerized**: the token and repo URL are passed as environment variables (`REPO_URL`, `RUNNER_TOKEN`) to the `github/` Docker Compose service, which runs `config.sh --url "$REPO_URL" --token "$RUNNER_TOKEN" --unattended --replace` followed by `run.sh` (see `github/start.sh`). Create a `.env` file (or export the variables) before running `docker compose up --build` inside `github/`.
3. **Native**: download the runner package for your OS from the repository's "New self-hosted runner" page, extract it, then run the same `config.sh`/`config.cmd` and `run.sh`/`run.cmd` commands directly on the host.
4. Tokens expire quickly (about 1 hour) — generate a fresh one right before configuring the runner.

## 2. GitLab CI/CD

1. On the target GitLab project, go to **Settings → CI/CD → Runners** and copy the registration token (or the new "runner authentication token" for newer GitLab versions).
2. **Containerized**: set `GITLAB_URL` and `GITLAB_REGISTRATION_TOKEN` in `gitlab/.env`, then `docker compose up --build` inside `gitlab/`. The container entrypoint (`gitlab/entrypoint.sh`) calls `gitlab/register-runner.sh`, which runs:
   ```sh
   gitlab-runner register --non-interactive --url "$GITLAB_URL" --token "$GITLAB_REGISTRATION_TOKEN" --executor "shell"
   ```
   The `shell` executor was used throughout this project, so pipeline steps run directly against the container's (or host's) filesystem rather than inside a nested Docker container.
3. **Native**: install `gitlab-runner` for your OS, then run the same `gitlab-runner register` command with `--executor shell` directly on the host.
4. Registration is only performed once — the resulting `config.toml` is persisted in a volume (`gitlab-runner-config`) so subsequent container restarts skip re-registration.

## 3. Azure Pipelines

1. In Azure DevOps, create an **Agent Pool** (this project used a pool named `TeseMestradoPool`) and generate a Personal Access Token (PAT) with **Agent Pools (read, manage)** scope.
2. **Containerized**: set `AZP_URL`, `AZP_TOKEN`, `AZP_POOL` (and optionally `AZP_AGENT_NAME`) as environment variables for the `azureDevOps/` Docker Compose service. `azureDevOps/start.sh` runs:
   ```sh
   ./config.sh --unattended --url "$AZP_URL" --auth pat --token "$AZP_TOKEN" --pool "$AZP_POOL" --agent "$(hostname)" --replace --acceptTeeEula
   ./run.sh
   ```
3. **Native**: download the agent package for your OS from the Agent Pool's "New agent" page in Azure DevOps and run the equivalent `config.sh`/`config.cmd` and `run.sh`/`run.cmd` on the host.
4. The pipeline definition must reference the same pool name (`pool: { name: TeseMestradoPool }`).

## 4. Jenkins

Jenkins does not have a lightweight "runner" concept — it requires the full server plus its plugins. See [jenkins/JENKINS.md](jenkins/JENKINS.md) for the original setup notes; the steps are summarized (and translated) below:

1. Run the Jenkins container: `docker compose -f jenkins/docker-compose-jenkins.yml up --build`. Do **not** delete the `jenkins_home` volume afterward, or all configuration/credentials will be lost.
2. Open `http://localhost:8080` and install these plugins (installation can be flaky — retry if a plugin fails):
   - GitHub Integration Plugin
   - GitHub Plugin
   - Docker Pipeline Plugin
3. Create a **Freestyle project** (this project used the name `teseMestrado`), point it at the repository URL with the appropriate credentials, and enable **"GitHub hook trigger for GITScm polling"**.
4. Paste the contents of the application's `jenkins/Jenkinsfile` (or the pipeline script) into the job's pipeline configuration.
5. Expose Jenkins to the internet so GitHub webhooks can reach it: `ngrok http http://localhost:8080`.
6. On GitHub, add a webhook to the repository pointing at `https://<your-ngrok-subdomain>.ngrok-free.app/github-webhook/`, with content type `application/json`.

## Grafana/Prometheus wiring for containerized runners

Each containerized runner also starts a `cAdvisor` process that exposes a Prometheus-compatible `/metrics` endpoint on a dedicated host port (GitHub: 9102, Jenkins: 9103, GitLab: 9104, Azure Pipelines: 9105). These ports are scraped by Prometheus — see [RESOURCE_CONSUMPTION_EXPERIMENT.md](RESOURCE_CONSUMPTION_EXPERIMENT.md) for how to bring that stack up.
