
resource "google_compute_instance_template" "template-west1" {
  count    = var.region == "us-west1" ? 1 : 0
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
  name               = "instance-group-west1"
  base_instance_name = "instance-west1"
  zone               = "us-west1-a"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-west1[count.index].self_link
    name              = "primary"
  }
}

resource "google_compute_region_health_check" "health_check-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  name               = "http-health-check-west1"
  http_health_check {
    port = 80
    request_path = "/"
  }

  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold   = 2
}

resource "google_compute_region_backend_service" "backend_service-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  name                  = "my-backend-service-west1"
  protocol              = "HTTP"
  region                = "us-west1"
  load_balancing_scheme = "INTERNAL_MANAGED"
  backend {
    group = google_compute_instance_group_manager.group-west1[count.index].instance_group
    balancing_mode      = "UTILIZATION"  # Choose the correct balancing mode
    capacity_scaler     = 1.0              # Set a valid capacity scaler
  }
  health_checks = [google_compute_region_health_check.health_check-west1[count.index].self_link]
}

resource "google_compute_region_url_map" "url_map-west" {
  count    = var.region == "us-west1" ? 1 : 0
  name            = "my-url-map-west1"
  default_service = google_compute_region_backend_service.backend_service-west1[count.index].self_link
}

resource "google_compute_region_target_http_proxy" "http_proxy-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  name    = "my-http-proxy-west1"
  region = "us-west1"
  url_map = google_compute_region_url_map.url_map-west[count.index].self_link
}

resource "google_compute_forwarding_rule" "http_forwarding_rule-west1" {
  count    = var.region == "us-west1" ? 1 : 0
  name                  = "my-forwarding-rule-west1"
  target                = google_compute_region_target_http_proxy.http_proxy-west1[count.index].self_link
  load_balancing_scheme = "INTERNAL_MANAGED"
  region                = "us-west1"
  port_range            = "80"
  network               = var.vpc_id
  subnetwork            = var.lb_subnet_id
  ip_address            = var.lb_ip_address
  allow_global_access   = true
}

resource "google_compute_instance_template" "template-east1" {
  count    = var.region == "us-east1" ? 1 : 0
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
  name               = "instance-group-east1"
  base_instance_name = "instance-east1"
  zone               = "us-east1-b"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.template-east1[count.index].self_link
    name              = "primary"
  }
}

resource "google_compute_region_health_check" "health_check-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  name               = "http-health-check-east1"
  http_health_check {
    port = 80
    request_path = "/"
  }

  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold   = 2
}

resource "google_compute_region_backend_service" "backend_service-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  name                  = "my-backend-service-east1"
  protocol              = "HTTP"
  region                = "us-east1"
  load_balancing_scheme = "INTERNAL_MANAGED"
  backend {
    group = google_compute_instance_group_manager.group-east1[count.index].instance_group
    balancing_mode      = "UTILIZATION"  # Choose the correct balancing mode
    capacity_scaler     = 1.0              # Set a valid capacity scaler
  }
  health_checks = [google_compute_region_health_check.health_check-east1[count.index].self_link]
}

resource "google_compute_region_url_map" "url_map-east" {
  count    = var.region == "us-east1" ? 1 : 0
  name            = "my-url-map-east1"
  default_service = google_compute_region_backend_service.backend_service-east1[count.index].self_link
}

resource "google_compute_region_target_http_proxy" "http_proxy-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  name    = "my-http-proxy-east1"
  region = "us-east1"
  url_map = google_compute_region_url_map.url_map-east[count.index].self_link
}

resource "google_compute_forwarding_rule" "http_forwarding_rule-east1" {
  count    = var.region == "us-east1" ? 1 : 0
  name                  = "my-forwarding-rule-east1"
  target                = google_compute_region_target_http_proxy.http_proxy-east1[count.index].self_link
  load_balancing_scheme = "INTERNAL_MANAGED"
  region                = "us-east1"
  port_range            = "80"
  network               = var.vpc_id
  subnetwork            = var.lb_subnet_id
  ip_address            = var.lb_ip_address
  allow_global_access   = true
}
