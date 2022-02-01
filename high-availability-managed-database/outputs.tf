output "load_balancer_ip" {
  value = google_compute_address.ip_address.address
}
