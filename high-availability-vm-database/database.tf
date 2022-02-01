resource "google_compute_instance" "db" {
  name         = "filemage-postgresql"
  machine_type = "f1-micro"
  tags         = ["filemage-postgresql"]

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "ubuntu-1804-bionic-v20200610"
      size  = 30
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    startup-script = templatefile("${path.module}/scripts/initialize-database.sh", {
      pg_password = var.pg_password
    })
  }
}
