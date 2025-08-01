
# 1. Health Check
resource "google_compute_region_health_check" "ilb_health_check" {
  project = var.project_id
  name    = "${var.ilb_name}-hc"
  region  = var.region

  # Health check type based on protocol
  dynamic "tcp_health_check" {
    for_each = var.protocol == "TCP" ? [1] : []
    content {
      port = var.health_check_port
    }
  }

  # dynamic "udp_health_check" {
  #   for_each = var.protocol == "UDP" ? [1] : []
  #   content {
  #     port = var.health_check_port
  #   }
  # }

  check_interval_sec  = var.health_check_interval_sec
  timeout_sec         = var.health_check_timeout_sec
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold
}

# 2. Backend Service
# Note: Internal Passthrough Network Load Balancers use regional backend services
resource "google_compute_region_backend_service" "ilb_backend_service" {
  project     = var.project_id
  name        = "${var.ilb_name}-bs"
  region      = var.region
  protocol    = var.protocol
  load_balancing_scheme = "INTERNAL_MANAGED" # For internal passthrough ILB

  health_checks = [google_compute_region_health_check.ilb_health_check.id]

  # Add backends (instance groups or NEGs)
  dynamic "backend" {
    for_each = var.backend_instance_groups
    content {
      group = backend.value # Expects self_link of instance group
    }
  }

  # If you want to support NEGs, you'd add another dynamic block for network_endpoint_groups
  # For simplicity, this example focuses on instance groups.
  # If you need NEGs, the 'google_compute_region_network_endpoint_group' resource would be used
  # and referenced here.

  # Optional: Connection draining timeout
  connection_draining_timeout_sec = var.connection_draining_timeout_sec
}

# 3. Static Internal IP Address (Optional)
resource "google_compute_address" "ilb_ip_address" {
  count        = var.allocate_static_ip ? 1 : 0
  project      = var.project_id
  name         = "${var.ilb_name}-ip"
  region       = var.region
  subnetwork   = var.subnetwork_self_link
  address_type = "INTERNAL"
  address      = var.static_ip_address
}

# 4. Forwarding Rule
resource "google_compute_forwarding_rule" "ilb_forwarding_rule" {
  project = var.project_id
  name    = "${var.ilb_name}-fr"
  region  = var.region

  load_balancing_scheme = "INTERNAL_MANAGED" # For internal passthrough ILB
  backend_service       = google_compute_region_backend_service.ilb_backend_service.id
  network               = var.network_self_link
  subnetwork            = var.subnetwork_self_link
  ip_protocol           = var.protocol # TCP or UDP

  # Use the allocated static IP if requested, otherwise use ephemeral
  ip_address = var.allocate_static_ip ? google_compute_address.ilb_ip_address[0].address : null

  # Define ports
  port_range = var.port_range
  # Or specific ports
  # ports = var.ports # Uncomment if you prefer specific ports over range

  labels = var.labels
}
