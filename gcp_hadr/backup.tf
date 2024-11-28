data "google_compute_instance" "vm_instance" {
  name    = var.vm_name
  zone    = var.zone
  project = var.project_id
}

resource "google_backup_dr_backup_vault" "backup-vault-test" {
  provider     = google-beta
  location = var.region
  backup_vault_id  = "gcp-hadr-backup-vault"
  backup_minimum_enforced_retention_duration    = "100000s"
}

resource "google_backup_dr_backup_plan" "backup-plan" {
  provider     = google-beta
  location       = var.region
  backup_plan_id = "gcp-hadr-backup-plan"
  resource_type  = "compute.googleapis.com/Instance"
  backup_vault   = google_backup_dr_backup_vault.backup-vault-test.id

  backup_rules {
    rule_id                = "rule-1"
    backup_retention_days  = 2

    standard_schedule {
      recurrence_type     = "HOURLY"
      hourly_frequency    = 6
      time_zone           = "UTC"

      backup_window {
        start_hour_of_day = 12
        end_hour_of_day   = 18
      }
    }
  }
}

resource "google_backup_dr_backup_plan_association" "backup-plan-association" {
  provider     = google-beta
  location = var.region
  resource_type= "compute.googleapis.com/Instance"
  backup_plan_association_id          = "gcp-hadr-backup-plan-association"
  resource      = data.google_compute_instance.vm_instance.id
  backup_plan  = google_backup_dr_backup_plan.backup-plan.name
}