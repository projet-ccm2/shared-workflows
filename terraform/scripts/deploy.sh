#!/bin/bash

# Script de déploiement Terraform pour Google Cloud Kubernetes
# Usage: ./deploy.sh <environment> [action]
# Exemple: ./deploy.sh dev plan
# Exemple: ./deploy.sh prod apply

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

# Vérification des paramètres
if [ $# -lt 1 ]; then
    error "Usage: $0 <environment> [action]"
    error "Environments: dev, int, prod"
    error "Actions: plan, apply, destroy, init"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}

# Vérification de l'environnement
if [[ ! "$ENVIRONMENT" =~ ^(dev|int|prod)$ ]]; then
    error "Environment must be one of: dev, int, prod"
    exit 1
fi

# Vérification de l'action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|init)$ ]]; then
    error "Action must be one of: plan, apply, destroy, init"
    exit 1
fi

# Configuration des fichiers
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"
STATE_FILE="terraform.tfstate.${ENVIRONMENT}"

log "Starting Terraform deployment for environment: $ENVIRONMENT"
log "Action: $ACTION"
log "Configuration file: $TFVARS_FILE"

# Vérification de l'existence du fichier de configuration
if [ ! -f "$TFVARS_FILE" ]; then
    error "Configuration file not found: $TFVARS_FILE"
    error "Please create the configuration file for environment: $ENVIRONMENT"
    exit 1
fi

# Vérification des prérequis
log "Checking prerequisites..."

# Vérification de Terraform
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed"
    exit 1
fi

# Vérification de Google Cloud CLI
if ! command -v gcloud &> /dev/null; then
    error "Google Cloud CLI is not installed"
    exit 1
fi

# Vérification de l'authentification Google Cloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    error "Not authenticated with Google Cloud"
    error "Please run: gcloud auth login"
    exit 1
fi

success "Prerequisites check passed"

# Initialisation de Terraform
if [ "$ACTION" = "init" ] || [ ! -d ".terraform" ]; then
    log "Initializing Terraform..."
    terraform init
    success "Terraform initialized"
fi

# Configuration du backend (optionnel)
if [ -n "$TF_STATE_BUCKET" ]; then
    log "Configuring Terraform backend..."
    terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$ENVIRONMENT"
fi

# Exécution de l'action Terraform
case $ACTION in
    "plan")
        log "Running Terraform plan..."
        terraform plan -var-file="$TFVARS_FILE" -state="$STATE_FILE"
        success "Terraform plan completed"
        ;;
    "apply")
        log "Running Terraform apply..."
        terraform apply -var-file="$TFVARS_FILE" -state="$STATE_FILE" -auto-approve
        success "Terraform apply completed"
        
        # Configuration kubectl après déploiement
        log "Configuring kubectl..."
        CLUSTER_NAME=$(grep 'cluster_name' "$TFVARS_FILE" | cut -d'"' -f2)
        REGION=$(grep 'region' "$TFVARS_FILE" | cut -d'"' -f2)
        ZONE=$(grep 'zone' "$TFVARS_FILE" | cut -d'"' -f2)
        
        if [ -n "$CLUSTER_NAME" ] && [ -n "$ZONE" ]; then
            gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"
            success "kubectl configured for cluster: $CLUSTER_NAME"
            
            # Vérification du déploiement
            log "Checking deployment status..."
            kubectl get nodes
            kubectl get pods -n "user-management-$ENVIRONMENT"
        fi
        ;;
    "destroy")
        warning "This will destroy all resources for environment: $ENVIRONMENT"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log "Running Terraform destroy..."
            terraform destroy -var-file="$TFVARS_FILE" -state="$STATE_FILE" -auto-approve
            success "Terraform destroy completed"
        else
            log "Destroy cancelled"
        fi
        ;;
    "init")
        success "Terraform initialization completed"
        ;;
esac

success "Deployment script completed successfully"
