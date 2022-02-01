data "google_compute_image" "filemage_public_image" {
  family  = "filemage-ubuntu"
  project = "filemage-public"
}

resource "google_compute_instance" "filemage" {
  name         = "filemage-app"
  machine_type = "f1-micro"
  tags         = [
    "filemage-app"
  ]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.filemage_public_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

}
