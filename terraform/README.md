# Terraform Configuration for Google Cloud Kubernetes

This Terraform configuration is integrated into CD workflows to automatically deploy infrastructure and applications on Google Kubernetes Engine (GKE).

## 🏗️ Structure

```
shared-workflows/
├── .github/
│   └── workflows/
│       ├── nodejs-ci.yml        # Reusable CI
│       ├── nodejs-cd.yml        # Reusable CD
│       └── terraform-deploy.yml # Terraform deployment
└── terraform/
    ├── main.tf                  # Main configuration
    ├── variables.tf             # Variables with validation
    └── environments/            # Environment-specific configurations
        ├── dev.tfvars           # Development configuration
        ├── int.tfvars           # Integration configuration
        └── prod.tfvars          # Production configuration
```

## 🚀 Integration with CD Workflows

### Automatic Triggering

CD workflows now use Terraform automatically:

- **cd-dev.yml** : Push to `develop` → Deploy to GKE dev
- **cd-int.yml** : Push to `main` → Deploy to GKE int  
- **cd-prod.yml** : Release/tag → Deploy to GKE prod

### Environment-Specific Configuration

Each environment has its own configuration:

#### Development
- **Cluster** : 1 node, e2-small
- **Resources** : Minimal (50m CPU, 64Mi RAM)
- **Autoscaling** : Disabled
- **Network Policy** : Disabled

#### Integration
- **Cluster** : 2 nodes, e2-medium
- **Resources** : Moderate (100m CPU, 128Mi RAM)
- **Autoscaling** : Enabled (2-5 nodes)
- **Network Policy** : Enabled

#### Production
- **Cluster** : 3 nodes, e2-standard
- **Resources** : Robust (200m CPU, 256Mi RAM)
- **Autoscaling** : Enabled (3-10 nodes)
- **Network Policy** : Enabled

## 🔧 Required Configuration

### GitHub Secrets

You need to configure these secrets in your GitHub repository:

#### Google Cloud Secrets
```
GCP_PROJECT_ID=your-gcp-project-id
GCP_SA_KEY=your-service-account-key
GCP_REGION=europe-west1
GCP_ZONE=europe-west1-a
```

#### Environment-Specific Secrets
```
# Development
GCP_CLUSTER_NAME_DEV=user-management-cluster-dev
DEV_DATABASE_URL=postgresql://dev-user:dev-password@dev-host:5432/dev-database
DEV_JWT_SECRET=dev-jwt-secret
DEV_API_KEY=dev-api-key
DEV_DOMAIN_NAME=dev.your-domain.com

# Integration
GCP_CLUSTER_NAME_INT=user-management-cluster-int
INT_DATABASE_URL=postgresql://int-user:int-password@int-host:5432/int-database
INT_JWT_SECRET=int-jwt-secret
INT_API_KEY=int-api-key
INT_DOMAIN_NAME=int.your-domain.com

# Production
GCP_CLUSTER_NAME_PROD=user-management-cluster-prod
PROD_DATABASE_URL=postgresql://prod-user:prod-password@prod-host:5432/prod-database
PROD_JWT_SECRET=prod-jwt-secret
PROD_API_KEY=prod-api-key
PROD_DOMAIN_NAME=your-domain.com
```

## 📋 Deployment Flow

### 1. Triggering
```bash
# Development
git push origin develop
# → cd-dev.yml executes
# → Terraform deploys infrastructure
# → Application deployed on GKE dev

# Integration
git push origin main
# → cd-int.yml executes
# → Terraform deploys infrastructure
# → Application deployed on GKE int

# Production
git tag v1.2.3
git push origin v1.2.3
# → cd-prod.yml executes
# → Terraform deploys infrastructure
# → Application deployed on GKE prod
```

### 2. Deployment Steps

1. **Checkout** code
2. **Setup Google Cloud CLI** with authentication
3. **Configure kubectl** for the cluster
4. **Terraform deployment** of infrastructure
5. **Application deployment** on Kubernetes
6. **Verification** of deployment
7. **Team notifications**

## 🔄 Shared Terraform Workflow

The `terraform-deploy.yml` workflow is reusable and accepts these parameters:

### Input Parameters
- `environment` : Environment (dev, int, prod)
- `project_id` : Google Cloud project ID
- `region` : Google Cloud region
- `zone` : Google Cloud zone
- `cluster_name` : GKE cluster name
- `database_url` : Database URL
- `jwt_secret` : JWT secret
- `api_key` : API key
- `github_owner` : GitHub repository owner
- `image_tag` : Docker image tag
- `domain_name` : Domain name
- `static_ip_name` : Static IP name (optional)

### Required Secrets
- `GCP_SA_KEY` : Google Cloud service account key

## 🎯 Benefits of this Approach

### Centralization
- ✅ **Centralized configuration** in shared-workflows
- ✅ **Reusability** between projects
- ✅ **Simplified maintenance**

### Environment-Specific Features
- ✅ **Differentiated variables** per environment
- ✅ **Adapted resources** (light dev, robust prod)
- ✅ **Enhanced security** in production

### Automation
- ✅ **Automatic deployment** via GitHub Actions
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Application deployment** on Kubernetes

## 🔧 Customization

### Modify Environment Configuration

Edit the corresponding file in `environments/`:

```hcl
# environments/dev.tfvars
node_count    = 2        # Increase number of nodes
machine_type  = "e2-medium"  # Change machine type
cpu_request   = "100m"   # Modify resources
```

### Add New Environments

1. Create a new file `environments/staging.tfvars`
2. Add corresponding GitHub secrets
3. Create a new CD workflow `cd-staging.yml`

### Modify Infrastructure

Edit `main.tf` to add new resources:
- Database
- Redis cache
- Monitoring
- Logging

## 📊 Monitoring

### Deployment Verification
```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -n user-management-dev

# Check services
kubectl get services -n user-management-dev

# Check ingresses
kubectl get ingress -n user-management-dev
```

### Application Logs
```bash
# Application logs
kubectl logs -f deployment/user-management-api -n user-management-dev

# Logs with selection
kubectl logs -f deployment/user-management-api -n user-management-dev --tail=100
```

## 🗑️ Cleanup

### Remove Environment
```bash
# Remove application
kubectl delete namespace user-management-dev

# Remove infrastructure
terraform destroy -var-file="environments/dev.tfvars"
```

## 📞 Support

For any questions:
1. Check Terraform documentation
2. Check GitHub Actions logs
3. Contact the DevOps team