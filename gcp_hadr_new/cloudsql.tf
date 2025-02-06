resource "google_sql_database_instance" "primary_sql_instance" {
  count    = var.region == "us-west4" ? 1 : 0
  name             = var.db_instance_name
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Change to appropriate machine type
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

