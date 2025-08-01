# GCP Passthrough Internal Load Balancer (ILB) Module

This Terraform module provisions a Google Cloud Platform (GCP) Regional Passthrough Internal Load Balancer (Internal TCP/UDP Load Balancer). It includes the necessary health check, regional backend service, and forwarding rule.

## Features

*   Supports TCP and UDP protocols.
*   Configurable health checks.
*   Supports existing Instance Groups as backends.
*   Option to allocate a static internal IP address.
*   Customizable port range for the frontend.

## Usage Example

To use this module, include it in your root Terraform configuration (`main.tf`) and provide the required input variables.

**Before you begin:**

*   Ensure you have a VPC network and a subnetwork created where you want to deploy the ILB and its backends.
*   Ensure you have existing Instance Groups (Managed Instance Groups or Unmanaged Instance Groups) that will serve as backends for the ILB.

```terraform
# main.tf in your root configuration

# Configure the Google Cloud provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Data source to get network self_link (replace with your network details)
data "google_compute_network" "default_network" {
  name    = "default" # Or your custom network name
  project = var.gcp_project_id
}

# Data source to get subnetwork self_link (replace with your subnetwork details)
data "google_compute_subnetwork" "default_subnetwork" {
  name    = "default" # Or your custom subnetwork name
  region  = var.gcp_region
  project = var.gcp_project_id
}

# Example: Data source to get an existing Instance Group's self_link
# Replace with your actual instance group details
data "google_compute_instance_group" "example_instance_group" {
  name    = "my-app-instance-group" # Name of your existing instance group
  zone    = "${var.gcp_region}-a" # Zone where your instance group is located
  project = var.gcp_project_id
}

module "app_ilb" {
  source = "./modules/gcp-passthrough-ilb" # Path to your local module

  project_id   = var.gcp_project_id
  region       = var.gcp_region
  ilb_name     = "my-app-internal-lb"
  protocol     = "TCP" # Or "UDP"

  network_self_link    = data.google_compute_network.default_network.self_link
  subnetwork_self_link = data.google_compute_subnetwork.default_subnetwork.self_link

  backend_instance_groups = [
    data.google_compute_instance_group.example_instance_group.self_link
  ]

  port_range        = "80" # Load balance traffic on port 80
  allocate_static_ip = true
  static_ip_address  = "10.128.1.10" # Must be an unused IP in the subnetwork range

  health_check_port = 8080 # Backend instances listen on 8080 for health checks
  labels = {
    environment = "dev"
    service     = "my-app"
  }
}

# Root outputs to display ILB details
output "ilb_frontend_ip" {
  description = "The IP address of the Internal Load Balancer."
  value       = module.app_ilb.ilb_ip_address
}

output "ilb_backend_service_url" {
  description = "The self_link of the ILB backend service."
  value       = module.app_ilb.ilb_backend_service_self_link
}
