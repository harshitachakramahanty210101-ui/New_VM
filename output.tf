output "network_self_link" {
  description = "VPC Network Self Link"
  value       = module.vpc.network_self_link
}

output "subnet_self_link" {
  description = "Subnet Self Link"
  value       = module.vpc.subnet_self_link
}

output "instance_group" {
  description = "Instance Group from VM Module"
  value       = module.vm.instance_group
}

output "load_balancer_url" {
  description = "Load Balancer URL"
  value       = module.loadbalancer.load_balancer_url
}
