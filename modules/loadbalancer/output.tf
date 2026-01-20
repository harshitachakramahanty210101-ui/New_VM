output "load_balancer_url" {
  description = "Load Balancer URL"
  value       = "http://${google_compute_global_forwarding_rule.default.ip_address}"
}
