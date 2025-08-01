

output "ilb_forwarding_rule_name" {
  description = "The name of the ILB forwarding rule."
  value       = google_compute_forwarding_rule.ilb_forwarding_rule.name
}

output "ilb_forwarding_rule_self_link" {
  description = "The self_link of the ILB forwarding rule."
  value       = google_compute_forwarding_rule.ilb_forwarding_rule.self_link
}

output "ilb_ip_address" {
  description = "The IP address of the ILB forwarding rule."
  value       = google_compute_forwarding_rule.ilb_forwarding_rule.ip_address
}

output "ilb_backend_service_name" {
  description = "The name of the ILB backend service."
  value       = google_compute_region_backend_service.ilb_backend_service.name
}

output "ilb_backend_service_self_link" {
  description = "The self_link of the ILB backend service."
  value       = google_compute_region_backend_service.ilb_backend_service.self_link
}

output "ilb_health_check_name" {
  description = "The name of the ILB health check."
  value       = google_compute_region_health_check.ilb_health_check.name
}
