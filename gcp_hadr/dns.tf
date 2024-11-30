data "google_compute_instance" "primary_vm" {
  name     = "gcp-hadr-web-primary"
  zone     = "us-west4-b"
  project  = var.hub_project_id
}

data "google_compute_instance" "secondary_vm" {
  provider = google-beta
  name     = "gcp-hadr-web-secondary"
  zone     = "us-east4-b"
  project  = var.hub_project_id
}

resource "google_dns_managed_zone" "dns_zone" {
  count       = var.region == "us-west1" ? 1 : 0
  name        = "hadr-gcp-dns"
  dns_name    = var.name
  description = "Managed DNdomain_S zone for failover setup"
  project     = var.project_id
  visibility  = "public"
}

resource "google_dns_record_set" "failover_record" {
  name         = "web.${var.domain_name}"
  managed_zone = google_dns_managed_zone.dns_zone[0].name
  type         = "A"
  ttl          = 10

  # Adding primary and failover configurations
  rrdatas = [
    data.google_compute_instance.primary_vm.network_interface[0].access_config[0].nat_ip, # Primary VM IP
    data.google_compute_instance.secondary_vm.network_interface[0].access_config[0].nat_ip # Secondary VM IP
  ]

  routing_policy {
    geo {
        location = "us-east4"
        rrdatas  =  [data.google_compute_instance.secondary_vm.network_interface[0].access_config[0].nat_ip]
    }
  }
}
