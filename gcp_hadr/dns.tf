resource "google_dns_managed_zone" "dns_zone" {
  count    = var.region == "us-west1" ? 1 : 0
  name        = "hadr-gcp-dns"
  dns_name    = var.domain_name
  description = "Managed DNS zone for failover setup"
  project     = var.project_id
  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc-west1[count.index].id
    }
  }
}

resource "google_dns_record_set" "a" {
  count    = var.region == "us-west1" ? 1 : 0
  name         = "app.${google_dns_managed_zone.dns_zone[count.index].dns_name}"
  managed_zone = google_dns_managed_zone.dns_zone[count.index].name
  type         = "A"
  ttl          = 10

  routing_policy {
    primary_backup {
      primary {
        internal_load_balancers {
          ip_address         = google_compute_forwarding_rule.http_forwarding_rule-west1[count.index].ip_address
          port               = "80"
          ip_protocol        = "tcp"
          network_url        = google_compute_network.vpc-west1[count.index].id
          project            = google_compute_forwarding_rule.http_forwarding_rule-west1[count.index].project
          region             = google_compute_forwarding_rule.http_forwarding_rule-west1[count.index].region
        }
      }

      backup_geo {
        location = "us-east1"
        rrdatas  = ["10.0.4.2"]
      }
    }
  }
}
