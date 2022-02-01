resource "google_compute_network" "vpc" {
  name                    = "filemage-vpc"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_global_address" "private_ip_block" {
  name          = "filemage-ip-block"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 20
  network       = google_compute_network.vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_dns_managed_zone" "private" {
  name        = "filemage-internal-dns"
  dns_name    = "filemage.internal." # Trailing dot is required.
  description = "Filemage internal DNS"

  labels = {
    purpose = "filemage"
  }

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "database" {
  name = "database.${google_dns_managed_zone.private.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private.name

  rrdatas = [google_sql_database_instance.main_primary.private_ip_address]
}
