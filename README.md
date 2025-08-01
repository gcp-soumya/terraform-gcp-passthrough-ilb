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

# Inputs

Name	Description	Type	Default	Required
  project_id	The GCP project ID where the ILB will be created.	string	n/a	yes
  region	The GCP region where the ILB will be deployed.	string	n/a	yes
  ilb_name	The name for the Internal Load Balancer resources (e.g., 'my-app-ilb').	string	n/a	yes
  protocol	The protocol for the ILB. Can be 'TCP' or 'UDP'.	string	"TCP"	no
  network_self_link	The self_link of the VPC network where the ILB will be deployed. e.g., projects/PROJECT_ID/global/networks/NETWORK_NAME.	string	n/a	yes
  subnetwork_self_link	The self_link of the subnetwork where the ILB will be deployed. e.g., projects/PROJECT_ID/regions/REGION/subnetworks/SUBNETWORK_NAME.	string	n/a	yes
  backend_instance_groups	A list of self_links of the instance groups that will serve as backends for the ILB. (e.g., projects/PROJECT_ID/zones/ZONE/instanceGroups/INSTANCE_GROUP_NAME).	list(string)	[]	no
  port_range	The port range (e.g., '80-80' or '80') that the ILB will listen on. Required for Internal Passthrough Network Load Balancers.	string	n/a	yes
  allocate_static_ip	Set to true to allocate a static internal IP address for the ILB.	bool	true	no
  static_ip_address	The static internal IP address to assign to the ILB. Required if allocate_static_ip is true. Must be within the specified subnetwork's IP range.	string	null	no
  health_check_port	The port for the health check. Can be the service port or a dedicated health check port.	number	80	no
  health_check_interval_sec	How often (in seconds) to send a health check request.	number	5	no
  health_check_timeout_sec	How long (in seconds) to wait for a response to a health check request.	number	5	no
  health_check_healthy_threshold	Number of consecutive successful health checks before considering an instance healthy.	number	2	no
  health_check_unhealthy_threshold	Number of consecutive failed health checks before considering an instance unhealthy.	number	2	no
  connection_draining_timeout_sec	Time (in seconds) to wait for connections to drain from a backend instance when it is removed.	number	0	no
  labels	A map of key/value labels to assign to the ILB resources.	map(string)	{}	no

# Outputs 

Name	Description
  ilb_forwarding_rule_name	The name of the ILB forwarding rule.
  ilb_forwarding_rule_self_link	The self_link of the ILB forwarding rule.
  ilb_ip_address	The IP address of the ILB forwarding rule.
  ilb_backend_service_name	The name of the ILB backend service.
  ilb_backend_service_self_link	The self_link of the ILB backend service.
  ilb_health_check_name	The name of the ILB health check.

# Requirements

  This module requires the Google Cloud provider configured with appropriate authentication. Ensure the service account or user running Terraform has the necessary permissions to create and manage:

  Compute Health Checks (compute.healthChecks.*)
  Compute Backend Services (compute.backendServices.*)
  Compute Forwarding Rules (compute.forwardingRules.*)
  Compute Addresses (compute.addresses.*)
  Access to read Network and Subnetwork information (compute.networks.get, compute.subnetworks.get)