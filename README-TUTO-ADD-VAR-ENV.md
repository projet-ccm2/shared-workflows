# Guide : Ajouter une variable d'environnement

Ce guide explique comment ajouter une nouvelle variable d'environnement au workflow de déploiement Cloud Run.

## Étapes

### 1. Ajouter la variable dans votre workflow de déploiement

Dans votre fichier de workflow (ex: `.github/workflows/cd-development.yml`), ajoutez la variable dans la section `secrets:` du job qui appelle le workflow réutilisable.

**Exemple :**

```yaml
name: Deploy to Development
on:
  push:
    branches:
      - develop
  workflow_dispatch:
    inputs:
      image-tag:
        description: "Docker image tag to deploy (default: dev-{sha})"
        required: false
        type: string
        default: ""
      force-deploy:
        description: "Force deployment even if no changes"
        required: false
        type: boolean
        default: false

jobs:
  deploy-dev:
    name: Deploy to Development
    uses: projet-ccm2/shared-workflows/.github/workflows/nodejs-cd.yml@main
    if: github.event_name != 'pull_request'
    with:
      docker-image-name: twitch-event-listener-api-dev
      docker-tag: ${{ github.event.inputs.image-tag || format('dev-{0}', github.sha) }}
      artifact-registry-repository: "twitch-event-listener-docker-dev"
      environment: development
      cloud-run-service-name: twitch-event-listener-dev
    secrets:
      GCP_SA_KEY: ${{ secrets.DEV_GCP_SA_KEY }}
      GCP_PROJECT_ID: ${{ secrets.DEV_GCP_PROJECT_ID }}  # ← Exemple : ajout de GCP_PROJECT_ID
      # Note : Si la variable change selon l'environnement, ajoutez le préfixe approprié (DEV_, INT_, PROD_)
      # Ne supprimez pas les secrets existants, ajoutez simplement le nouveau
```

**Points importants :**
- Si la variable change selon l'environnement, utilisez le préfixe approprié : `DEV_`, `INT_`, ou `PROD_`
- Ne supprimez pas les secrets existants, ajoutez simplement le nouveau secret

### 2. Ajouter le secret dans GitHub

Ajoutez le secret dans les **Settings → Secrets and variables → Actions** de votre repository GitHub.

**Convention de nommage :**
- Si la variable est spécifique à un environnement, utilisez le préfixe approprié :
  - `DEV_GCP_PROJECT_ID` pour l'environnement de développement
  - `INT_GCP_PROJECT_ID` pour l'environnement d'intégration
  - `PROD_GCP_PROJECT_ID` pour l'environnement de production
- Si la variable est commune à tous les environnements, utilisez simplement le nom de la variable (ex: `GCP_PROJECT_ID`)

**Exemple :**
Si vous avez besoin de `GCP_PROJECT_ID` qui change selon l'environnement, créez :
- `DEV_GCP_PROJECT_ID`
- `INT_GCP_PROJECT_ID`
- `PROD_GCP_PROJECT_ID`

### 3. Demander l'ajout de la variable dans le workflow réutilisable

Contactez l'équipe DevOps pour ajouter la variable d'environnement dans le workflow réutilisable (`shared-workflows/.github/workflows/nodejs-cd.yml`).

**Important :**
- Utilisez le nom de la variable **sans préfixe** (ex: `GCP_PROJECT_ID`, pas `DEV_GCP_PROJECT_ID`)
- Vérifiez dans le README principal si la variable n'existe pas déjà avant de faire la demande

### 4. Tester le déploiement

Une fois toutes les étapes complétées, vous pouvez lancer votre workflow de déploiement (CD). La nouvelle variable d'environnement sera automatiquement passée à Cloud Run.

## Résumé

1. ✅ Ajouter le secret dans votre workflow de déploiement (section `secrets:`)
2. ✅ Créer le secret dans GitHub (avec le préfixe approprié si nécessaire)
3. ✅ Demander l'ajout de la variable dans le workflow réutilisable (nom sans préfixe)
4. ✅ Tester le déploiement
