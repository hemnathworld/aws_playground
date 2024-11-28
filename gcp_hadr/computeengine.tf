resource "google_compute_instance" "vm_instance_primary" {
  count    = var.region == "us-west4" ? 1 : 0
  provider     = google.hub
  name         = "gcp-hadr-web-primary"
  machine_type = "e2-micro"
  zone         = "us-west4-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_id
    access_config {}
  }
  metadata_startup_script = templatefile("${path.module}/scripts/us-west1-script.sh", {PROJECT_ID = var.project_id})
}


resource "google_compute_instance" "vm_instance_secondary" {
  count    = var.region == "us-east4" ? 1 : 0
  provider     = google.hub
  name         = "gcp-hadr-web-primary"
  machine_type = "e2-micro"
  zone         = "us-east4-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_id
    access_config {}
  }
  metadata_startup_script = templatefile("${path.module}/scripts/us-east1-script.sh", {PROJECT_ID = var.project_id})
}
