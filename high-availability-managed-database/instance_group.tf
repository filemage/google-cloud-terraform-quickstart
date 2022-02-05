data "google_compute_image" "filemage_public_image" {
  family  = "filemage-ubuntu"
  project = "filemage-public"
}

resource "google_service_account" "instance" {
  account_id   = "filamge-instance-account"
  display_name = "FileMage Application Server Account"
}

data "google_iam_policy" "instance_read_secret" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.instance.email}",
    ]
  }
}

resource "google_compute_instance_template" "filemage" {
  depends_on = [
    google_sql_database_instance.read_replica,
    google_secret_manager_secret_version.database_password,
    google_secret_manager_secret_version.application_secret,
  ]

  name_prefix  = "filemage-app-"
  machine_type = "f1-micro"
  tags         = ["filemage-app"]

  disk {
    source_image = data.google_compute_image.filemage_public_image.self_link
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    startup-script = templatefile("${path.module}/scripts/initialize-application.sh", {
      pg_host     = google_dns_record_set.database.name
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    email  = google_service_account.instance.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_group_manager" "filemage" {
  name = "filemage-mig"

  base_instance_name = "filemage-app"
  target_pools       = [google_compute_target_pool.default.id]
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.filemage.id
  }
}
