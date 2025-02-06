resource "google_sql_database_instance" "sql_instance" {
  name             = "db-instance"
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
  name     = "mydatabase"
  instance = google_sql_database_instance.sql_instance.name
}
