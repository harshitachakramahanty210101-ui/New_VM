output "network_self_link" {
  value = google_compute_network.custom_vpc.self_link
}

output "subnet_self_link" {
  value = google_compute_subnetwork.custom_subnet.self_link
}