terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "kubernetes" {
  host  = google_container_cluster.primary.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

data "google_client_config" "default" {}
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "europe-west1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "user-management-cluster"
}

variable "environment" {
  description = "Environment (dev, int, prod)"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  deletion_protection = false

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    labels = {
      environment = var.environment
      project     = "user-management"
    }

    tags = ["gke-node", "${var.environment}-node"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  node_pool {
    name       = "default-pool"
    node_count = var.node_count

    node_config {
      machine_type = var.machine_type
      disk_size_gb = var.disk_size_gb
      disk_type    = var.disk_type

      labels = {
        environment = var.environment
        project     = "user-management"
      }

      tags = ["gke-node", "${var.environment}-node"]

      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }

    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "user-management-${var.environment}"
    labels = {
      environment = var.environment
      project      = "user-management"
    }
  }
}

resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "user-management-secrets"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    DATABASE_URL = var.database_url
    JWT_SECRET   = var.jwt_secret
    API_KEY      = var.api_key
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "user-management-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    NODE_ENV           = var.environment
    PORT               = "3000"
    LOG_LEVEL          = var.environment == "prod" ? "info" : "debug"
    HEALTH_CHECK_PATH  = "/health"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "user-management-api"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app     = "user-management-api"
      version = "v1"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "user-management-api"
      }
    }

    template {
      metadata {
        labels = {
          app     = "user-management-api"
          version = "v1"
        }
      }

      spec {
        container {
          name  = "user-management-api"
          image = "ghcr.io/${var.github_owner}/user-management-api:${var.image_tag}"

          port {
            container_port = 3000
            protocol       = "TCP"
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "JWT_SECRET"
              }
            }
          }

          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "API_KEY"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = var.health_check_path
              port = 3000
            }
            initial_delay_seconds = var.liveness_probe_initial_delay
            period_seconds        = var.liveness_probe_period
          }

          readiness_probe {
            http_get {
              path = var.health_check_path
              port = 3000
            }
            initial_delay_seconds = var.readiness_probe_initial_delay
            period_seconds        = var.readiness_probe_period
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "user-management-api-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "user-management-api"
    }

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}


variable "database_url" {
  description = "Database URL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API Key"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner/organization"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "static_ip_name" {
  description = "Name of the static IP resource"
  type        = string
  default     = ""
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "service_ip" {
  description = "External IP of the LoadBalancer service"
  value       = kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}