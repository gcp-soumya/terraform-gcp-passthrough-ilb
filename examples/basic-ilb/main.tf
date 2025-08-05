# examples/basic-ilb/main.tf

module "internal_load_balancer" {
  source = "../../modules/gcp-ilb-passthrough" # Path to your module

  project_id               = var.project_id
  region                   = var.region
  zone                     = var.zone
  ilb_name_prefix          = "my-app-ilb"
  backend_instance_count   = 2
  backend_machine_type     = "e2-medium"
  ilb_protocol             = "TCP"
  ilb_port_range           = "80"
  health_check_port        = 80
  subnetwork_ip_cidr_range = "10.20.0.0/20" # New CIDR for the example
  source_ranges_ingress    = ["0.0.0.0/0"]  # WARNING: Broad access, narrow this in production!
}


