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
| `registry-url` | string | No | `ghcr.io` | Registry URL |
| `gcp-project-id` | string | **Yes** | - | Google Cloud Project ID |
| `gcp-region` | string | No | `europe-west1` | Google Cloud region |
| `cloud-run-service-name` | string | **Yes** | - | Cloud Run service name |
| `cloud-run-port` | string | No | `8080` | Cloud Run service port |
| `cloud-run-memory` | string | No | `512Mi` | Cloud Run memory allocation |
| `cloud-run-cpu` | string | No | `1` | Cloud Run CPU allocation |
| `cloud-run-max-instances` | string | No | `10` | Cloud Run max instances |

#### Required Secrets

| Secret | Type | Required | Description |
|--------|------|----------|-------------|
| `REGISTRY_TOKEN` | string | **Yes** | Registry authentication token |
| `GCP_SA_KEY` | string | **Yes** | Google Cloud Service Account key (JSON) |

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
      gcp-project-id: my-gcp-project
      cloud-run-service-name: my-app-service
      gcp-region: europe-west1
      cloud-run-memory: 1Gi
      cloud-run-cpu: 2
    secrets:
      REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
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
