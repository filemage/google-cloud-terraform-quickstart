resource "random_id" "database_suffix" {
  byte_length = 4
}

resource "google_sql_database" "main" {
  name     = "filemage-db"
  instance = google_sql_database_instance.main_primary.name
}

resource "google_sql_user" "db_user" {
  name     = "filemage"
  instance = google_sql_database_instance.main_primary.name
  password = var.pg_password
  deletion_policy = "ABANDON"
}

resource "google_sql_database_instance" "main_primary" {
  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  name             = "filemage-db-primary-${random_id.database_suffix.hex}"
  database_version = "POSTGRES_16"
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    edition           = "ENTERPRISE"
    availability_type = "REGIONAL"
    disk_size         = 10

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.self_link
    }

    location_preference {
      zone = var.zone
    }

    database_flags {
      name  = "cloudsql.enable_pg_cron"
      value = "on"
    }
  }
}