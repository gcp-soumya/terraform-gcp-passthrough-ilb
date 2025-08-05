# modules/gcp-ilb-passthrough/variables.tf

variable "project_id" {
  description = "The GCP project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for the load balancer and instances."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for the managed instance group. (Only one zone for Zonal MIG)"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the VPC network to use. If `create_network` is true, this will be the name of the new network."
  type        = string
  default     = "ilb-module-network"
}

variable "create_network" {
  description = "Whether to create a new VPC network. If false, an existing network must be specified."
  type        = bool
  default     = true
}

variable "subnetwork_name" {
  description = "The name of the subnetwork to use. If `create_subnetwork` is true, this will be the name of the new subnetwork."
  type        = string
  default     = "ilb-module-subnet"
}

variable "create_subnetwork" {
  description = "Whether to create a new subnetwork. If false, an existing subnetwork must be specified."
  type        = bool
  default     = true
}

variable "subnetwork_ip_cidr_range" {
  description = "The IP CIDR range for the new subnetwork. Required if `create_subnetwork` is true."
  type        = string
  default     = "10.10.0.0/20"
}

variable "ilb_name_prefix" {
  description = "A prefix for naming all load balancer related resources."
  type        = string
  default     = "ilb-tcp"
}

variable "ilb_protocol" {
  description = "The protocol for the Internal Load Balancer (TCP or UDP)."
  type        = string
  default     = "TCP"
  validation {
    condition     = var.ilb_protocol == "TCP"
    error_message = "The ILB protocol must be 'TCP'. UDP is not supported in this module version."
  }
}


variable "ilb_static_ip_address" {
  description = "Optional: A specific internal IP address for the ILB forwarding rule. If empty, an ephemeral internal IP will be assigned from the subnetwork."
  type        = string
  default     = null
}

variable "backend_instance_count" {
  description = "The number of backend instances in the managed instance group."
  type        = number
  default     = 2
}

variable "backend_machine_type" {
  description = "The machine type for the backend instances."
  type        = string
  default     = "e2-small"
}

variable "backend_image" {
  description = "The source image for the backend instances."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "backend_startup_script" {
  description = "Startup script for backend instances. This script will install Apache and serve a simple message."
  type        = string
  default     = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    echo "Hello from $(hostname) - Internal Load Balancer!" | sudo tee /var/www/html/index.html
    sudo systemctl enable apache2
    sudo systemctl start apache2
  EOF
}

variable "health_check_port" {
  description = "The port for the health check on backend instances."
  type        = number
  default     = 80
}

variable "source_ranges_ingress" {
  description = "List of CIDR ranges that are allowed to connect to the ILB. Defaults to allow all internal traffic."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # Common private IP ranges
}

variable "ilb_port_range" {
  description = "The port for the ILB forwarding rule (e.g., '80'). 'ALL' is also supported for all ports. Note: Port ranges are not supported for internal passthrough Network Load Balancers with backend services; only single ports or 'ALL' can be specified."
  type        = string
  default     = "80"
  validation {
    condition     = var.ilb_port_range == "ALL" || can(tonumber(var.ilb_port_range))
    error_message = "The ilb_port_range must be 'ALL' or a single port number (e.g., '80')."
  }
}

variable "health_check_type" {
  description = "The type of health check (TCP or HTTP)."
  type        = string
  default     = "HTTP" # Changed default to HTTP
  validation {
    condition     = contains(["TCP", "HTTP"], upper(var.health_check_type))
    error_message = "The health_check_type must be 'TCP' or 'HTTP'."
  }
}