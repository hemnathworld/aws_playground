resource "google_sql_database_instance" "primary_sql_instance" {
  count    = var.region == "us-west4" ? 1 : 0
  name             = "primary-db-instance"
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
resource "google_sql_database" "database" {
  count    = var.region == "us-west4" ? 1 : 0
  name     = "myprimarydatabase"
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_database_instance" "sql_instance" {
  count    = var.region == "us-east4" ? 1 : 0
  name             = "secondary-db-instance"
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
resource "google_sql_database" "database" {
  count    = var.region == "us-west4" ? 1 : 0
  name     = "myprimarydatabase"
  instance = google_sql_database_instance.sql_instance.name
}

