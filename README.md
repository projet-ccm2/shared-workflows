# Shared GitHub Workflows

This repository contains reusable GitHub Actions workflows to centralize CI/CD for your projects.

## Structure

```
shared-workflows/
├── .github/
│   └── workflows/
│       ├── nodejs-ci.yml    # CI workflow for Node.js projects
│       └── nodejs-cd.yml    # CD workflow for Node.js projects
└── README.md
```

## Available Workflows

### 1. Node.js CI (`nodejs-ci.yml`)

CI workflow for Node.js projects with support for:
- Tests with coverage
- ESLint
- SonarQube (optional)
- Customizable installation and build

#### Input Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `node-version` | string | No | `22.13.1` | Node.js version to use |
| `test-command` | string | No | `npm run test:coverage` | Command to run tests |
| `eslint-command` | string | No | `npx eslint .` | Command to run ESLint |
| `install-command` | string | No | `npm install` | Command to install dependencies |
| `fetch-depth` | string | No | `0` | Git fetch depth |
| `pr-number` | string | No | - | Pull request number (for SonarQube PR analysis) |
| `pr-branch` | string | No | - | Pull request branch name (for SonarQube PR analysis) |
| `pr-base` | string | No | - | Pull request base branch (for SonarQube PR analysis) |

#### Required Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `SONAR_TOKEN` | No | SonarQube token (if provided, enables SonarQube analysis) |
| `GITHUB_TOKEN_SECRET` | No | GitHub token for SonarQube to comment on PRs (automatically provided by GitHub Actions) |

#### Jobs

- **sonarqube** : Tests + SonarQube (if `SONAR_TOKEN` provided)
- **eslint** : ESLint verification
- **test-only** : Tests only (if no `SONAR_TOKEN`)

### 2. Node.js CD (`nodejs-cd.yml`)

CD workflow for Node.js projects with support for:
- Application build
- Docker image construction
- Push to registry
- Automatic Artifact Registry repository creation
- Cloud Run deployment
- Health check validation

#### Input Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `node-version` | string | No | `22.13.1` | Node.js version to use |
| `build-command` | string | No | `npm run build` | Build command |
| `install-command` | string | No | `npm install` | Installation command |
| `dockerfile-path` | string | No | `./Dockerfile` | Path to Dockerfile |
| `docker-context` | string | No | `.` | Docker context |
| `docker-image-name` | string | **Yes** | - | Docker image name |
| `docker-tag` | string | No | `latest` | Docker tag |
| `registry-url` | string | No | `europe-west1-docker.pkg.dev` | Registry URL |
| `environment` | string | **Yes** | - | Environment (dev, staging, prod) |
| `health-check-url` | string | No | `/health` | Health check route (e.g., `/health`, `/api/health`) - URL is auto-generated from Cloud Run service |
| `health-check-timeout` | string | No | `60` | Health check timeout in seconds |
| `gcp-region` | string | No | `europe-west1` | Google Cloud region |
| `cloud-run-service-name` | string | **Yes** | - | Cloud Run service name |
| `cloud-run-port` | string | No | `3000` | Cloud Run service port |
| `cloud-run-memory` | string | No | `512Mi` | Cloud Run memory allocation |
| `cloud-run-cpu` | string | No | `1` | Cloud Run CPU allocation |
| `cloud-run-max-instances` | string | No | `10` | Cloud Run max instances |
| `cloud-run-min-instances` | string | No | `0` | Cloud Run min instances |
| `artifact-registry-repository` | string | **Yes** | - | Artifact Registry repository name |
| `required_env_vars` | string | **Yes** (integration/production) | - | Comma-separated list of env var names that must be non-empty when `environment` is `integration` or `production` (e.g. `DB_SERVICE_URL,DATABASE_URL`). Obligatory when `environment` is `integration` or `production`; the workflow fails at the end of the run if this input is empty or if any listed variable is missing. |
| `service_type` | string | **Yes** (when not development) | - | Cloud Run type: `front` \| `bff` \| `back_prive`. Required and validated when `environment` is not `development` (must be exactly one of these values). Ignored when `environment` is `development`. For `bff` and `back_prive`, the VPC connector is fixed to `streamquest-vpc-2-conn` (hardcoded); the workflow checks that it exists in the region before deploying. |

#### Features

- **Automatic Artifact Registry Management**: The workflow automatically checks if the specified Artifact Registry repository exists and creates it if it doesn't exist
- **Parameter Validation**: Comprehensive validation of all required inputs and secrets before deployment
- **Health Check**: Optional health check validation after deployment using auto-generated URL. For private services (`back_prive` when not in development), the workflow uses an identity token so the check can authenticate to Cloud Run (the deploy service account must have `roles/run.invoker` on the service).
- **Environment Variables**: NODE_ENV and GCP_PROJECT_ID as plain env vars. All other vars are passed via GitHub secrets; the workflow syncs them to [Secret Manager](https://cloud.google.com/secret-manager) and Cloud Run reads from there—so they are not visible in the Cloud Run console. Naming: GitHub secret names map to Secret Manager IDs in kebab-case (e.g. `JWT_SECRET` → `jwt-secret`, `IA_SERVICE_URL` → `ia-service-url`, `NOTIFICATION_HANDLER_URL` → `notification-handler-url`). `ALLOWED_ORIGINS` is stored per service as `allowed-origins-<cloud-run-service-name>`. The deploy service account (GCP_SA_KEY) must have `roles/secretmanager.admin` (or create/update permissions) to sync secrets.
- **Env vars validation (integration/production)**: When `environment` is `integration` or `production`, set `required_env_vars` (e.g. `DB_SERVICE_URL,JWT_SECRET`). The workflow validates that these GitHub secrets are set before deploy.
- **Service type (FRONT \| BFF \| BACK_PRIVE)**: When `environment` is not `development`, you must set `service_type` to `front`, `bff`, or `back_prive`. This controls Cloud Run ingress, authentication, and VPC connector: **front** = public (ingress all, allow-unauthenticated); **bff** = public + VPC connector; **back_prive** = internal only (ingress internal, no allow-unauthenticated, VPC connector). Auth is handled in the app (e.g. Twitch OAuth), no IAP. The VPC connector name is hardcoded (`streamquest-vpc-2-conn`) for bff and back_prive; the workflow verifies it exists in the region before deploy. Load Balancer / NEG (without IAP) are configured outside this workflow (e.g. Terraform).
- **Multi-tag Support**: Automatic generation of multiple Docker tags (branch, commit-sha, custom tag)
- **Secure Secret Handling**: All sensitive vars come from Secret Manager by default—not visible in the Cloud Run console.

#### Secrets (GitHub)

**Required**

| Secret | Type | Description |
|--------|------|-------------|
| `GCP_SA_KEY` | string | Google Cloud Service Account key (JSON) for deploy auth |
| `GCP_PROJECT_ID` | string | Google Cloud Project ID |

**Optional** (pass only what the app needs; each non-empty value is synced to Secret Manager, then mounted on Cloud Run under the same env var name)

| Secret | Secret Manager ID | Description |
|--------|-------------------|-------------|
| `ALLOWED_ORIGINS` | `allowed-origins-<cloud-run-service-name>` | Allowed CORS / origin configuration |
| `AUTH_SERVICE_URL` | `auth-service-url` | Auth service base URL |
| `CACHE_TTL` | `cache-ttl` | Cache TTL |
| `DATABASE_URL` | `database-url` | Database connection URL |
| `DB_GATEWAY_BASE_URL` | `db-gateway-base-url` | DB gateway base URL |
| `DB_SERVICE_URL` | `db-service-url` | DB / data service URL |
| `DISPATCHER_URL` | `dispatcher-url` | Dispatcher service URL |
| `FRONT_URL` | `front-url` | Front-end URL |
| `GCP_BUCKET_NAME` | `gcp-bucket-name` | GCS bucket name |
| `IA_SERVICE_URL` | `ia-service-url` | IA / AI service URL |
| `JWT_SECRET` | `jwt-secret` | JWT signing secret |
| `MYSQL_DATABASE` | `mysql-database` | MySQL database name |
| `MYSQL_PASSWORD` | `mysql-password` | MySQL password |
| `MYSQL_USER` | `mysql-user` | MySQL user |
| `NOTIFICATION_HANDLER_URL` | `notification-handler-url` | Notification handler service URL |
| `PUBLIC_EVENTSUB_CALLBACK` | `public-eventsub-callback` | Public EventSub callback URL |
| `REDIS_URL` | `redis-url` | Redis connection URL |
| `SYNC_INTERVAL_MS` | `sync-interval-ms` | Sync interval in milliseconds |
| `TWITCH_APP_ACCESS_TOKEN` | `twitch-app-access-token` | Twitch app access token |
| `TWITCH_CLIENT_ID` | `twitch-client-id` | Twitch client ID |
| `TWITCH_ISSUER` | `twitch-issuer` | Twitch issuer |
| `TWITCH_WEBHOOK_SECRET` | `twitch-webhook-secret` | Twitch webhook secret |
| `USE_MOCK` | `use-mock` | Use mock backends / flags |

The workflow syncs these GitHub secrets to Secret Manager before deploy (creates/updates secrets). Cloud Run reads from Secret Manager—values are not visible in the console. The deploy SA needs `roles/secretmanager.admin`; the Cloud Run service identity needs `roles/secretmanager.secretAccessor`.

## Usage

### In a local project

```yaml
# .github/workflows/ci.yml
name: ci
on:
  push:
    branches: [main, develop]
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  ci:
    uses: ./.github/workflows/shared-workflows/.github/workflows/nodejs-ci.yml
    with:
      pr-number: ${{ github.event.number }}
      pr-branch: ${{ github.head_ref }}
      pr-base: ${{ github.base_ref }}
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      GITHUB_TOKEN_SECRET: ${{ secrets.GITHUB_TOKEN }}
```

```yaml
# .github/workflows/cd.yml
name: cd
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: ./.github/workflows/shared-workflows/.github/workflows/nodejs-cd.yml
    with:
      docker-image-name: my-app
      docker-tag: latest
      environment: production
      artifact-registry-repository: my-repo
      cloud-run-service-name: my-app-service
      gcp-region: europe-west1
      cloud-run-memory: 1Gi
      cloud-run-cpu: 2
      health-check-url: /health
      required_env_vars: DB_SERVICE_URL,JWT_SECRET
    secrets:
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
      DB_SERVICE_URL: ${{ secrets.DB_SERVICE_URL }}
      IA_SERVICE_URL: ${{ secrets.IA_SERVICE_URL }}
      NOTIFICATION_HANDLER_URL: ${{ secrets.NOTIFICATION_HANDLER_URL }}
      JWT_SECRET: ${{ secrets.JWT_SECRET }}
      # ... other optional secrets (see table above; synced to Secret Manager before deploy)
```

### In a separate repository

Once you've moved the `shared-workflows` folder to a separate repository (e.g., `my-org/shared-workflows`), you can use it like this:

```yaml
# .github/workflows/ci.yml
name: ci
on:
  push:
    branches: [main, develop]
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  ci:
    uses: my-org/shared-workflows/.github/workflows/nodejs-ci.yml@main
    permissions:
      contents: read
      pull-requests: write
    with:
      node-version: '20.0.0'
      test-command: 'npm run test:ci'
      pr-number: ${{ github.event.number }}
      pr-branch: ${{ github.head_ref }}
      pr-base: ${{ github.base_ref }}
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      GITHUB_TOKEN_SECRET: ${{ secrets.GITHUB_TOKEN }}
```

## Customization

### Add project-specific secrets

To add project-specific secrets, simply modify the `secrets` section in your local workflow:

```yaml
jobs:
  ci:
    uses: my-org/shared-workflows/.github/workflows/nodejs-ci.yml@main
    permissions:
      contents: read
      pull-requests: write
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      GITHUB_TOKEN_SECRET: ${{ secrets.GITHUB_TOKEN }}
      # New project-specific secrets
      CUSTOM_SECRET: ${{ secrets.CUSTOM_SECRET }}
```

### CD workflow secrets

Pass secrets via GitHub; the workflow syncs them to Secret Manager before deploy. Only include the ones your service needs. For integration/production, list any mandatory vars in `required_env_vars` (e.g. `IA_SERVICE_URL,NOTIFICATION_HANDLER_URL`) so the workflow fails if a repository secret is missing or empty.

### Secret Manager sync

The workflow syncs GitHub secrets to Secret Manager before each deploy (creates secrets if needed, adds new versions). Cloud Run reads from Secret Manager—values are hidden in the console. Ensure:

1. The deploy service account (GCP_SA_KEY) has `roles/secretmanager.admin` to create/update secrets
2. The Cloud Run service identity has `roles/secretmanager.secretAccessor` to read them

### Customize commands

```yaml
jobs:
  ci:
    uses: my-org/shared-workflows/.github/workflows/nodejs-ci.yml@main
    with:
      node-version: '18.0.0'
      test-command: 'npm run test:unit'
      eslint-command: 'npm run lint'
      install-command: 'npm ci'
    permissions:
      contents: read
      pull-requests: write
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      GITHUB_TOKEN_SECRET: ${{ secrets.GITHUB_TOKEN }}
      JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

## Migration

### Step 1: Prepare the shared repository

1. Create a new repository: `my-org/shared-workflows`
2. Copy the content of the `shared-workflows/` folder to this new repository
3. Commit and push the files

### Step 2: Update your projects

1. In each project, replace the local path with the remote repository
2. Test the workflows
3. Delete the old local `shared-workflows/` folder

### Migration example

**Before:**
```yaml
uses: ./.github/workflows/shared-workflows/.github/workflows/nodejs-ci.yml
```

**After:**
```yaml
uses: my-org/shared-workflows/.github/workflows/nodejs-ci.yml@main
```

## Benefits

- ✅ **Centralization** : Single place to maintain workflows
- ✅ **Consistency** : Same CI/CD process for all projects
- ✅ **Flexibility** : Customization possible per project
- ✅ **Maintenance** : Centralized updates
- ✅ **Reusability** : Easy to share between teams
- ✅ **Infrastructure Management** : Automatic creation of required GCP resources
- ✅ **Validation** : Comprehensive parameter and secret validation
- ✅ **Health Monitoring** : Built-in health check validation
