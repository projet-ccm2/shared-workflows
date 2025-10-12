project_id   = "your-gcp-project-id"
region       = "europe-west1"
zone         = "europe-west1-a"
cluster_name = "user-management-cluster-dev"

environment = "dev"

node_count    = 1
machine_type  = "e2-micro"
disk_size_gb  = 10
disk_type     = "pd-standard"

github_owner = "your-github-username"
image_tag    = "dev-latest"
domain_name  = "dev.your-domain.com"

database_url = "postgresql://dev-user:dev-password@dev-host:5432/dev-database"
jwt_secret   = "dev-jwt-secret"
api_key      = "dev-api-key"

enable_autoscaling = false
min_node_count    = 1
max_node_count    = 1

cpu_request    = "25m"
memory_request  = "32Mi"
cpu_limit      = "100m"
memory_limit   = "128Mi"

health_check_path = "/health"
liveness_probe_initial_delay  = 60
liveness_probe_period         = 30
readiness_probe_initial_delay = 10
readiness_probe_period        = 10

maintenance_window_start_time = "03:00"

enable_network_policy = false
enable_http_load_balancing = false
enable_horizontal_pod_autoscaling = false