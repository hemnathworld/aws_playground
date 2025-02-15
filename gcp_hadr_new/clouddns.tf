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


resource "google_dns_record_set" "dns_failover" {
  count       = var.region == "us-west1" ? 1 : 0
  name = "web"
  type = "A"
  ttl  = 30
  managed_zone = var.dns_zone_name

  rrdatas = [
    data.google_compute_forwarding_rule.us_west_forwarding_rule.ipaddress,
    data.google_compute_forwarding_rule.us_east_forwarding_rule.ipaddress,
  ]

  routing_policy {
    geo {
      primary_targets = [data.google_compute_forwarding_rule.us_west_forwarding_rule.ipaddress]
      failover_targets = [data.google_compute_forwarding_rule.us_east_forwarding_rule.ipaddress]
    }
  }
}
