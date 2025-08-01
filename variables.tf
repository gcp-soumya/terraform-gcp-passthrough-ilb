# modules/gcp-passthrough-ilb/variables.tf

variable "project_id" {
  description = "The GCP project ID where the ILB will be created."
  type        = string
}

variable "region" {
  description = "The GCP region where the ILB will be deployed."
  type        = string
}

variable "ilb_name" {
  description = "The name for the Internal Load Balancer resources (e.g., 'my-app-ilb')."
  type        = string
}

variable "protocol" {
  description = "The protocol for the ILB. Can be 'TCP' or 'UDP'."
  type        = string
  default     = "TCP"
  validation {
    condition     = contains(["TCP", "UDP"], upper(var.protocol))
    error_message = "Protocol must be 'TCP' or 'UDP'."
  }
}

variable "network_self_link" {
  description = "The self_link of the VPC network where the ILB will be deployed. e.g., projects/PROJECT_ID/global/networks/NETWORK_NAME."
  type        = string
}

variable "subnetwork_self_link" {
  description = "The self_link of the subnetwork where the ILB will be deployed. e.g., projects/PROJECT_ID/regions/REGION/subnetworks/SUBNETWORK_NAME."
  type        = string
}

variable "backend_instance_groups" {
  description = "A list of self_links of the instance groups that will serve as backends for the ILB. (e.g., projects/PROJECT_ID/zones/ZONE/instanceGroups/INSTANCE_GROUP_NAME)."
  type        = list(string)
  default     = []
}

# Frontend configuration
variable "port_range" {
  description = "The port range (e.g., '80-80' or '80') that the ILB will listen on. Required for Internal Passthrough Network Load Balancers."
  type        = string
}

/*
# Alternative to port_range, if you prefer explicit ports
variable "ports" {
  description = "A list of specific ports (e.g., ['80', '443']) that the ILB will listen on. Use this OR port_range."
  type        = list(string)
  default     = null
}
*/

variable "allocate_static_ip" {
  description = "Set to true to allocate a static internal IP address for the ILB."
  type        = bool
  default     = true
}

variable "static_ip_address" {
  description = "The static internal IP address to assign to the ILB. Required if `allocate_static_ip` is true. Must be within the specified subnetwork's IP range."
  type        = string
  default     = null
}

# Health Check configuration
variable "health_check_port" {
  description = "The port for the health check. Can be the service port or a dedicated health check port."
  type        = number
  default     = 80
}

variable "health_check_interval_sec" {
  description = "How often (in seconds) to send a health check request."
  type        = number
  default     = 5
}

variable "health_check_timeout_sec" {
  description = "How long (in seconds) to wait for a response to a health check request."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks before considering an instance healthy."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before considering an instance unhealthy."
  type        = number
  default     = 2
}

# Backend Service configuration
variable "connection_draining_timeout_sec" {
  description = "Time (in seconds) to wait for connections to drain from a backend instance when it is removed."
  type        = number
  default     = 0 # No connection draining by default
}

variable "labels" {
  description = "A map of key/value labels to assign to the ILB resources."
  type        = map(string)
  default     = {}
}
