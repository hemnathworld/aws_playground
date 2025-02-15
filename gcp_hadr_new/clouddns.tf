data "google_compute_forwarding_rule" "us_west_forwarding_rule" {
  name = "my-forwarding-rule-west4"
}

data "google_compute_forwarding_rule" "us_east_forwarding_rule" {
  name = "my-forwarding-rule-east4"
}


resource "google_dns_managed_zone" "dns_zone" {
  count       = var.region == "us-west1" ? 1 : 0
  name        = "hadr-gcp-dns"
  dns_name    = var.dns_zone_name
  description = "Managed DNS zone for failover setup"
  project     = var.hub_project_id
  visibility  = "public"
}

resource "google_compute_health_check" "http-health-check" {
  name        = "http-health-check"
  description = "Health check via http"

  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_dns_record_set" "dns_failover" {
  count       = var.region == "us-west1" ? 1 : 0
  name = "web"
  type = "A"
  ttl  = 5
  managed_zone = var.dns_zone_name

  routing_policy {
    health_check = google_compute_health_check.http-health-check.id
    primary_backup {

      primary {
        external_endpoints = [data.google_compute_forwarding_rule.us_west_forwarding_rule.ipaddress]
      }

      backup_geo {
        location = "us-west4"
        health_checked_targets {
          external_endpoints = [data.google_compute_forwarding_rule.us_east_forwarding_rule.ipaddress]
        }
      }
    }
  }
}
