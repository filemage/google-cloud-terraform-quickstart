resource "google_compute_network" "vpc" {
  name                    = "filemage-vpc"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "app" {
  name          = "filemage-app"
  network       = google_compute_network.vpc.self_link
  priority      = "1001"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["443", "21", "22", "2222", "80", "32768-65535"]
  }

  target_tags = ["filemage-app"]
}
