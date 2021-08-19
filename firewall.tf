resource "google_compute_firewall" "app" {
  name          = "filemage-app"
  network       = "default"
  priority      = "1001"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["443", "21", "2222", "80"]
  }

  target_tags = ["filemage-app"]
}

# FTP clients connect directly to app VMs, bypassing load balancer.
resource "google_compute_firewall" "ftp_passive" {
  name          = "filemage-ftp-passive"
  network       = "default"
  priority      = "1002"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["32768-65535"]
  }

  target_tags = ["filemage-app"]
}

resource "google_compute_firewall" "postgresql" {
  name          = "filemage-postgresql"
  network       = "default"
  priority      = "1001"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags = ["filemage-postgresql"]
}
