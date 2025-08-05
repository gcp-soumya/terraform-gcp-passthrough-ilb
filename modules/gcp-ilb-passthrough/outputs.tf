# modules/gcp-ilb-passthrough/outputs.tf

output "ilb_ip_address" {
  description = "The internal IP address of the Passthrough Internal Load Balancer."
  value       = google_compute_forwarding_rule.ilb_forwarding_rule.ip_address
}

output "ilb_forwarding_rule_self_link" {
  description = "Self link of the ILB forwarding rule."
  value       = google_compute_forwarding_rule.ilb_forwarding_rule.self_link
}

output "backend_service_self_link" {
  description = "Self link of the backend service."
  value       = google_compute_region_backend_service.ilb_backend_service.self_link
}

output "network_self_link" {
  description = "Self link of the network used by the ILB."
  value       = local.network_self_link
}

output "subnetwork_self_link" {
  description = "Self link of the subnetwork used by the ILB."
  value       = local.subnetwork_self_link
}
