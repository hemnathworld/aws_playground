resource "google_compute_global_address" "primary_private_ip_range" {
  count    = var.region == "us-west4" ? 1 : 0
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = <>
}

resource "google_service_networking_connection" "primary_private_vpc_connection" {
  network       = <>
  service       = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.primary_private_ip_range.name]
}

resource "google_sql_database_instance" "primary_sql_instance" {
  count    = var.region == "us-west4" ? 1 : 0
  name             = var.db_instance_name
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Change to appropriate machine type
    ip_configuration {
      ipv4_enabled    = false   # Disable External IP
      private_network = "projects/{{project}}/regional/networks/{{name}}"
    }
    backup_configuration {
      enabled            = true
      point_in_time_recovery_enabled = true
    }
  }
}

# Cloud SQL Database
resource "google_sql_database" "primary_database" {
  count    = var.region == "us-west4" ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.primary_sql_instance.name
}

resource "google_sql_database_instance" "secondary_sql_instance" {
  count    = var.region == "us-east4" ? 1 : 0
  name             = var.db_instance_name
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Change to appropriate machine type
    ip_configuration {
      ipv4_enabled    = false   # Disable External IP
      private_network = <>
    }
    backup_configuration {
      enabled            = true
      point_in_time_recovery_enabled = true
    }
  }
}

# Cloud SQL Database
resource "google_sql_database" "secondary_database" {
  count    = var.region == "us-east4" ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.secondary_sql_instance.name
}

# Cloud Function to export SQL to GCS
resource "google_storage_bucket_object" "cloud_function_code" {
  count    = var.region == "us-west4" ? 1 : 0
  name   = "export_function.zip"
  bucket = var.us_west_bucket_name
  source = "export_function.zip"  # Ensure this zip file exists locally
}

resource "google_cloudfunctions_function" "export_function" {
  count    = var.region == "us-west4" ? 1 : 0
  name        = "export-sql-to-gcs"
  runtime     = "python311"
  region      = var.region
  entry_point = "export_db"
  
  source_archive_bucket = var.us_west_bucket_name
  source_archive_object = google_storage_bucket_object.cloud_function_code.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.sql_export_topic.id
  }

  environment_variables = {
    SQL_INSTANCE  = google_sql_database_instance.sql_instance.name
    DB_NAME       = google_sql_database.database.name
    GCS_BUCKET    = var.us_west_bucket_name
  }
}

# Pub/Sub Topic for triggering Cloud Function
resource "google_pubsub_topic" "sql_export_topic" {
  count    = var.region == "us-west4" ? 1 : 0
  name = "sql-export-topic"
}

# Cloud Scheduler Job to trigger Cloud Function every 30 minutes
resource "google_cloud_scheduler_job" "export_scheduler" {
  count    = var.region == "us-west4" ? 1 : 0
  name        = "sql-export-job"
  region      = var.region
  schedule    = "*/30 * * * *"  # Runs every 30 minutes
  time_zone   = "UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.sql_export_topic.id
    data       = base64encode("Trigger Cloud SQL Export")
  }
}
