resource "google_compute_instance" "web_server" {
  count    = var.region == "us-west4" ? 1 : 0
  name         = "web-server-primary"
  machine_type = "e2-micro"
  zone         = "us-west4-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}  # Enable public IP
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y apache2
      systemctl start apache2
    EOT
  }

  tags = ["http-server"]
}


resource "google_pubsub_topic" "uptime_check_topic" {
  count    = var.region == "us-west4" ? 1 : 0
  name = "uptime-check-topic"
}

resource "google_pubsub_subscription" "uptime_check_subscription" {
  count    = var.region == "us-west4" ? 1 : 0
  name  = "uptime-check-subscription"
  topic = google_pubsub_topic.uptime_check_topic.name
}

resource "google_monitoring_uptime_check_config" "uptime_check" {
  count    = var.region == "us-west4" ? 1 : 0
  display_name = "web-server-uptime"
  monitored_resource {
    type   = "gce_instance"
    labels = {
      project_id   = var.project_id
      instance_id  = google_compute_instance.web_server.id
      zone         = google_compute_instance.web_server.zone
    }
  }

  http_check {
    path = "/"
    port = 80
  }

  timeout = "10s"
  period  = "20s"
}

resource "google_compute_snapshot" "web_server_snapshot" {
  count    = var.region == "us-west4" ? 1 : 0
  name        = "web-server-snapshot"
  source_disk = google_compute_instance.web_server.boot_disk[0].device_name
  zone        = "us-west4-b"
  storage_locations = ["us"]
}

resource "google_compute_snapshot_iam_member" "allow_dr_project" {
  count    = var.region == "us-west4" ? 1 : 0
  snapshot = google_compute_snapshot.primary_disk_snapshot.name
  role     = "roles/compute.storageAdmin"
  member   = "serviceAccount:${var.us_east_project_number}-compute@developer.gserviceaccount.com"
}

# 3. Use Snapshot in Secondary Project to Create Disk
resource "google_compute_disk" "dr_disk" {
  count    = var.region == "us-east4" ? 1 : 0
  name        = "dr-disk"
  type        = "pd-standard"
  zone        = "us-east4-b"
  source_snapshot = "projects/${var.us_west_project_number}/global/snapshots/web-server-snapshot"
}

# 4. Optional: Create Instance in DR Project Using DR Disk
resource "google_compute_instance" "dr_instance" {
  count    = var.region == "us-east4" ? 1 : 0
  name        = "dr-instance"
  machine_type = "e2-micro"
  zone         = "us-east4-b"

  boot_disk {
    source = google_compute_disk.dr_disk.id
  }

  network_interface {
    network    = "default"
    access_config {}
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      echo "Instance created from replicated disk"
    EOT
  }
}


