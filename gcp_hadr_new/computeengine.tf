resource "google_compute_instance_template" "template-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name        = "instance-template-west4"
  machine_type = "e2-micro"
  network_interface {
    network    = var.vpc_id
    subnetwork = var.us_west_subnet_id
    access_config {
    }
  }

  service_account {
    email  = "${var.us_west_project_id}-compute@developer.gserviceaccount.com"  # Default SA
    scopes = ["cloud-platform"]
  }

  tags = ["http-server", "https-server"]
  disk {
    source_image      = "debian-cloud/debian-11"
    auto_delete       = true
    boot              = true
  }
  metadata = {
    startup-script = templatefile("${path.module}/scripts/us-west4-script.sh", {PROJECT_ID = var.project_id})
  }
  shape_config {
    ocpus = 2
    memory_in_gbs = 16
}

resource "google_compute_instance_group_manager" "group-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name               = "hadr-instance-group-west4"
  base_instance_name = "hadr-instance-west4"
  zone               = "us-west4-b"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-west4[count.index].self_link
    name              = "primary"
  }
}


resource "google_compute_region_health_check" "health_check-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name               = "http-health-check-west4"
  http_health_check {
    port = 80
    request_path = "/"
  }

  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold   = 2
}

resource "google_compute_region_backend_service" "backend_service-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name                  = "my-backend-service-west4"
  protocol              = "HTTP"
  region                = "us-west4"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group = google_compute_instance_group_manager.group-west4[count.index].instance_group
    balancing_mode      = "UTILIZATION"  # Choose the correct balancing mode
    capacity_scaler     = 1.0              # Set a valid capacity scaler
  }
  health_checks = [google_compute_region_health_check.health_check-west4[count.index].self_link]
}

resource "google_compute_region_url_map" "url_map-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name            = "my-url-map-west4"
  project               = var.host_project_id
  default_service = google_compute_region_backend_service.backend_service-west4[count.index].self_link
}

resource "google_compute_region_target_http_proxy" "http_proxy-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  project               = var.host_project_id
  name    = "my-http-proxy-west4"
  region = "us-west4"
  url_map = google_compute_region_url_map.url_map-west4[count.index].self_link
}

resource "google_compute_forwarding_rule" "http_forwarding_rule-west4" {
  count    = var.region == "us-west4" ? 1 : 0
  name                  = "my-forwarding-rule-west4"
  project               = var.host_project_id
  target                = google_compute_region_target_http_proxy.http_proxy-west4[count.index].self_link
  load_balancing_scheme = "EXTERNAL_MANAGED"
  region                = "us-west4"
  port_range            = "80"
  network               = var.vpc_id
}







resource "google_compute_instance_template" "template-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name        = "instance-template-east4"
  machine_type = "e2-micro"
  network_interface {
    network    = var.vpc_id
    subnetwork = var.us_east_subnet_id
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
    startup-script = templatefile("${path.module}/scripts/us-east4-script.sh", {PROJECT_ID = var.project_id})
  }

}

resource "google_compute_instance_group_manager" "group-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name               = "hadr-instance-group-east4"
  base_instance_name = "hadr-instance-east4"
  zone               = "us-east4-b"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-east4[count.index].self_link
    name              = "primary"
  }
}


resource "google_compute_region_health_check" "health_check-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name               = "http-health-check-east4"
  http_health_check {
    port = 80
    request_path = "/"
  }

  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold   = 2
}

resource "google_compute_region_backend_service" "backend_service-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name                  = "my-backend-service-east4"
  protocol              = "HTTP"
  region                = "us-east4"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group = google_compute_instance_group_manager.group-east4[count.index].instance_group
    balancing_mode      = "UTILIZATION"  # Choose the correct balancing mode
    capacity_scaler     = 1.0              # Set a valid capacity scaler
  }
  health_checks = [google_compute_region_health_check.health_check-east4[count.index].self_link]
}

resource "google_compute_region_url_map" "url_map-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name            = "my-url-map-east4"
  project               = var.host_project_id
  default_service = google_compute_region_backend_service.backend_service-east4[count.index].self_link
}

resource "google_compute_region_target_http_proxy" "http_proxy-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  project               = var.host_project_id
  name    = "my-http-proxy-east4"
  region = "us-east4"
  url_map = google_compute_region_url_map.url_map-east4[count.index].self_link
}

resource "google_compute_forwarding_rule" "http_forwarding_rule-east4" {
  count    = var.region == "us-east4" ? 1 : 0
  name                  = "my-forwarding-rule-east4"
  project               = var.host_project_id
  target                = google_compute_region_target_http_proxy.http_proxy-east4[count.index].self_link
  load_balancing_scheme = "EXTERNAL_MANAGED"
  region                = "us-east4"
  port_range            = "80"
  network               = var.vpc_id
}
