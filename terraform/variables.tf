
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
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be one of: dev, int, prod."
  }
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

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "pd-standard"
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "maintenance_window_start_time" {
  description = "Maintenance window start time (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "replicas" {
  description = "Number of replicas for the application"
  type        = number
  default     = null
}

variable "cpu_request" {
  description = "CPU request for the application"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for the application"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the application"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for the application"
  type        = string
  default     = "512Mi"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "liveness_probe_initial_delay" {
  description = "Liveness probe initial delay in seconds"
  type        = number
  default     = 30
}

variable "liveness_probe_period" {
  description = "Liveness probe period in seconds"
  type        = number
  default     = 10
}

variable "readiness_probe_initial_delay" {
  description = "Readiness probe initial delay in seconds"
  type        = number
  default     = 5
}

variable "readiness_probe_period" {
  description = "Readiness probe period in seconds"
  type        = number
  default     = 5
}