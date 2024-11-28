resource "google_compute_instance_template" "template-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  provider     = google.hub
  name        = "instance-template-west1"
  machine_type = "e2-micro"
  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
    access_config {
    }
  }

  tags = ["http-server", "https-server"]
  disk {
    source_image      = "debian-cloud/debian-11"
    auto_delete       = true
    boot              = true
  }
  metadata = {
    startup-script = templatefile("${path.module}/scripts/us-west1-script.sh", {PROJECT_ID = var.project_id})
  }

}

resource "google_compute_instance_group_manager" "group-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  provider     = google.hub
  name               = "instance-group-west1"
  base_instance_name = "instance-west1"
  zone               = "us-west1-a"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-west1[count.index].self_link
    name              = "primary"
  }
}


resource "google_compute_instance_template" "template-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  provider     = google.hub
  name        = "instance-template-east1"
  machine_type = "e2-micro"
  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
    access_config {
    }
  }

  tags = ["http-server", "https-server"]
  disk {
    source_image      = "debian-cloud/debian-11"
    auto_delete       = true
    boot              = true
  }
  metadata = {
    startup-script = templatefile("${path.module}/scripts/us-east1-script.sh", {PROJECT_ID = var.project_id})
  }

}

resource "google_compute_instance_group_manager" "group-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  provider     = google.hub
  name               = "instance-group-east1"
  base_instance_name = "instance-east1"
  zone               = "us-east1-b"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-east1[count.index].self_link
    name              = "primary"
  }
}
