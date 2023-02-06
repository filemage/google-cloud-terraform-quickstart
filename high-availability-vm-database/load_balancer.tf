resource "google_compute_target_pool" "default" {
  name = "filemage-lb"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_http_health_check" "default" {
  name         = "port-80-healthcheck"
  request_path = "/healthz"
  timeout_sec        = 30
  check_interval_sec = 30
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
  target       = google_compute_target_tcp_proxy.sftp_proxy.self_link
  port_range   = "22"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}

resource "google_compute_target_tcp_proxy" "sftp_proxy" {
  name            = "filemage-sftp"
  backend_service = google_compute_backend_service.sftp_backend.id
  proxy_header    = "PROXY_V1"
}

resource "google_compute_backend_service" "sftp_backend" {
  name        = "filemage-sftp"
  description = "filemage"
  port_name   = "sftp"
  protocol    = "TCP"
  timeout_sec = 86400
  health_checks = [google_compute_health_check.sftp_healthcheck.id]

  backend {
    group = "${google_compute_instance_group_manager.filemage.instance_group}"
  }
}

resource "google_compute_health_check" "sftp_healthcheck" {
  name = "filemage-sftp"
  timeout_sec        = 30
  check_interval_sec = 30

  tcp_health_check {
    port = "2222"
  }
}

resource "google_compute_forwarding_rule" "ftp" {
  name         = "filemage-ftp"
  target       = google_compute_target_tcp_proxy.ftp_proxy.self_link
  port_range   = "21"
  ip_address   = google_compute_address.ip_address.address
  network_tier = "STANDARD"
}

resource "google_compute_target_tcp_proxy" "ftp_proxy" {
  name            = "filemage-ftp"
  backend_service = google_compute_backend_service.ftp_backend.id
  proxy_header    = "PROXY_V1"
}


resource "google_compute_backend_service" "ftp_backend" {
  name        = "filemage-ftp"
  description = "filemage"
  port_name   = "ftp"
  protocol    = "TCP"
  timeout_sec = 86400
  health_checks = [google_compute_health_check.ftp_healthcheck.id]

  backend {
    group = "${google_compute_instance_group_manager.filemage.instance_group}"
  }
}

resource "google_compute_health_check" "ftp_healthcheck" {
  name = "filemage-ftp"
  timeout_sec        = 30
  check_interval_sec = 30

  tcp_health_check {
    port = "21"
  }
}
