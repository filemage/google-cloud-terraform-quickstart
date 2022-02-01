resource "google_compute_target_pool" "default" {
  name = "filemage-lb"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_http_health_check" "default" {
  name         = "port-80-healthcheck"
  request_path = "/healthz"

  timeout_sec        = 1
  check_interval_sec = 1
}

resource "google_compute_address" "ip_address" {
  name         = "filemage-external-ip"
  network_tier = "STANDARD"
}

resource "google_compute_forwarding_rule" "http" {
  name         = "filemage-http"
  target       = google_compute_target_pool.default.id
  port_range   = "80"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}

resource "google_compute_forwarding_rule" "https" {
  name         = "filemage-https"
  target       = google_compute_target_pool.default.id
  port_range   = "443"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}

resource "google_compute_forwarding_rule" "sftp" {
  name         = "filemage-sftp"
  target       = google_compute_target_pool.default.id
  port_range   = "2222"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}

resource "google_compute_forwarding_rule" "ftp" {
  name         = "filemage-ftp"
  target       = google_compute_target_pool.default.id
  port_range   = "21"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}
