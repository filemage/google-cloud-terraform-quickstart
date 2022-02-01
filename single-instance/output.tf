output "load_balancer_ip" {
  value = google_compute_instance.filemage.network_interface.0.access_config.0.nat_ip
}
