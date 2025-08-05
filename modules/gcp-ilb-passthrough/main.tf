# modules/gcp-ilb-passthrough/main.tf

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. VPC Network (Optional: Create new or use existing)
resource "google_compute_network" "ilb_network" {
  count                   = var.create_network ? 1 : 0
  name                    = var.network_name
  auto_create_subnetworks = false
}

data "google_compute_network" "ilb_network_data" {
  count = var.create_network ? 0 : 1
  name  = var.network_name
}

locals {
  network_self_link = var.create_network ? google_compute_network.ilb_network[0].self_link : data.google_compute_network.ilb_network_data[0].self_link
}

# 2. Subnetwork (Optional: Create new or use existing)
resource "google_compute_subnetwork" "ilb_subnet" {
  count         = var.create_subnetwork ? 1 : 0
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_ip_cidr_range
  region        = var.region
  network       = local.network_self_link
}

data "google_compute_subnetwork" "ilb_subnet_data" {
  count  = var.create_subnetwork ? 0 : 1
  name   = var.subnetwork_name
  region = var.region
}

locals {
  subnetwork_self_link = var.create_subnetwork ? google_compute_subnetwork.ilb_subnet[0].self_link : data.google_compute_subnetwork.ilb_subnet_data[0].self_link
}

# 3. Instance Template for Managed Instance Group
resource "google_compute_instance_template" "backend_template" {
  name_prefix    = "${var.ilb_name_prefix}-backend-template-"
  machine_type   = var.backend_machine_type
  can_ip_forward = true # Required for Passthrough NLB backends

  disk {
    source_image = var.backend_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = local.network_self_link
    subnetwork = local.subnetwork_self_link
    # No external IP is needed for internal load balancer backends
  }

  metadata_startup_script = var.backend_startup_script

  tags = ["${var.ilb_name_prefix}-backends"]
}

# 4. Zonal Managed Instance Group (MIG)
resource "google_compute_instance_group_manager" "ilb_mig" {
  name               = "${var.ilb_name_prefix}-mig"
  zone               = var.zone
  base_instance_name = "${var.ilb_name_prefix}-backend"
  target_size        = var.backend_instance_count
  version {
    instance_template = google_compute_instance_template.backend_template.self_link
  }
}

# 5. Health Check (TCP only)
resource "google_compute_health_check" "ilb_health_check_tcp" {
  name               = "${var.ilb_name_prefix}-health-check-tcp"
  check_interval_sec = 5
  timeout_sec        = 5
  # tcp_health_check {
  #   port = var.health_check_port
  # }
  dynamic "tcp_health_check" {
    for_each = var.health_check_type == "TCP" ? [1] : []
    content {
      port = var.health_check_port
    }
  }

  dynamic "http_health_check" {
    for_each = var.health_check_type == "HTTP" ? [1] : []
    content {
      port = var.health_check_port
      request_path = "/" # Default path for HTTP health checks
    }
  }
}

# 6. Backend Service
resource "google_compute_region_backend_service" "ilb_backend_service" {
  name                  = "${var.ilb_name_prefix}-backend-service"
  protocol              = var.ilb_protocol # Will always be TCP now based on variable validation
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  health_checks         = [google_compute_health_check.ilb_health_check_tcp.self_link] # Directly reference TCP health check
  session_affinity      = "CLIENT_IP_PROTO"

  backend {
    group = google_compute_instance_group_manager.ilb_mig.instance_group
  }
}

# 7. Internal Static IP Address for the Load Balancer (Optional: if ilb_static_ip_address is provided)
resource "google_compute_address" "ilb_static_ip" {
  count        = var.ilb_static_ip_address != null ? 1 : 0
  name         = "${var.ilb_name_prefix}-static-ip"
  subnetwork   = local.subnetwork_self_link
  address_type = "INTERNAL"
  region       = var.region
  address      = var.ilb_static_ip_address
}

# 8. Forwarding Rule
resource "google_compute_forwarding_rule" "ilb_forwarding_rule" {
  name                  = "${var.ilb_name_prefix}-forwarding-rule"
  region                = var.region
  ip_protocol           = var.ilb_protocol # Will always be TCP now
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.ilb_backend_service.self_link
  network               = local.network_self_link
  subnetwork            = local.subnetwork_self_link
  ip_address            = var.ilb_static_ip_address != null ? google_compute_address.ilb_static_ip[0].self_link : null # Use static IP if provided, otherwise ephemeral
  
  all_ports             = var.ilb_port_range == "ALL" ? true : null
  ports = var.ilb_port_range != "ALL" ? [var.ilb_port_range] : null # Use null if not true to avoid setting false explicitly if not needed

}

# 9. Firewall Rules
# Firewall rule to allow health checks from GCP's health check IP ranges
resource "google_compute_firewall" "allow_health_check" {
  name          = "${var.ilb_name_prefix}-allow-health-check"
  network       = local.network_self_link
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP health check IP ranges
  target_tags   = google_compute_instance_template.backend_template.tags

  allow {
    protocol = lower(var.ilb_protocol) # Will always be "tcp"
    ports    = [tostring(var.health_check_port)]
  }
}

# Firewall rule to allow incoming traffic to the ILB's IP
resource "google_compute_firewall" "allow_ilb_ingress" {
  name          = "${var.ilb_name_prefix}-allow-ingress"
  network       = local.network_self_link
  source_ranges = var.source_ranges_ingress
  target_tags   = google_compute_instance_template.backend_template.tags

  allow {
    protocol = lower(var.ilb_protocol) # Will always be "tcp"
    ports    = var.ilb_port_range == "ALL" ? [] : [var.ilb_port_range]
  }
  allow {
    protocol = "icmp"
  }
}
