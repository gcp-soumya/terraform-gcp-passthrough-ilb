output "ilb_ip" {
  description = "The internal IP address of the created ILB."
  value       = module.internal_load_balancer.ilb_ip_address
}

output "ilb_forwarding_rule" {
  description = "The self link of the ILB forwarding rule."
  value       = module.internal_load_balancer.ilb_forwarding_rule_self_link
}
