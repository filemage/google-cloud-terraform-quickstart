data "google_compute_image" "filemage_public_image" {
  family  = "filemage-ubuntu"
  project = "filemage-public"
}

resource "google_compute_instance_template" "filemage" {
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
      pg_password = var.pg_password,
      pg_host     = google_compute_instance.db.network_interface.0.network_ip
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "filemage" {
  name = "filemage-mig"

  base_instance_name = "filemage-app"
  target_pools       = [google_compute_target_pool.default.id]
  target_size        = 2

  named_port {
    name = "ftp"
    port = 21
  }

  named_port {
    name = "sftp"
    port = 2222
  }

  version {
    instance_template = google_compute_instance_template.filemage.id
  }
}
