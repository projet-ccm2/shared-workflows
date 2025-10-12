project_id   = "your-gcp-project-id"
region       = "europe-west1"
zone         = "europe-west1-a"
cluster_name = "user-management-cluster-prod"

environment = "prod"

node_count    = 1
machine_type  = "e2-small"
disk_size_gb  = 20
disk_type     = "pd-standard"

github_owner = "your-github-username"
image_tag    = "prod-latest"
domain_name  = "your-domain.com"

database_url = "postgresql://prod-user:prod-password@prod-host:5432/prod-database"
jwt_secret   = "prod-jwt-secret"
api_key      = "prod-api-key"

enable_autoscaling = false
min_node_count    = 1
max_node_count    = 1

cpu_request    = "100m"
memory_request  = "128Mi"
cpu_limit      = "500m"
memory_limit   = "512Mi"

health_check_path = "/health"
liveness_probe_initial_delay  = 60
liveness_probe_period         = 30
readiness_probe_initial_delay = 10
readiness_probe_period        = 10

maintenance_window_start_time = "03:00"

enable_network_policy = false
enable_http_load_balancing = false
enable_horizontal_pod_autoscaling = false