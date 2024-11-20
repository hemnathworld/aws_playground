# Service Account
resource "google_service_account" "app_engine_sa" {
  account_id   = "app-engine-sa"
  display_name = "App Engine Service Account"
}

# Grant permissions to the Service Account
resource "google_project_iam_member" "app_engine_sa_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.app_engine_sa.email}"
}

# Upload app source code to Cloud Storage
resource "google_storage_bucket_object" "app_code_primary" {
  count    = var.region == "us-west1" ? 1 : 0
  name   = "sample-app-us-west1.zip"
  bucket = google_storage_bucket.primary_bucket.name
  source = "${path.module}/sample-app-us-west1.zip"
}

resource "google_storage_bucket_object" "app_code_secondary" {
  count    = var.region == "us-east1" ? 1 : 0
  name   = "sample-app-us-east1.zip"
  bucket = google_storage_bucket.primary_bucket.name
  source = "${path.module}/sample-app-us-east1.zip"
}

resource "google_app_engine_standard_app_version" "app_version_primary" {
  count    = var.region == "us-west1" ? 1 : 0
  service  = "default"
  version_id = "v1"
  runtime   = "python39"
  entrypoint {
    shell = "gunicorn -w 2 -b :8080 main:app"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/hemtestbucket-hadr-us-west1/sample-app-us-west1.zip"
    }
  }
  service_account = google_service_account.app_engine_sa.email
}

resource "google_app_engine_standard_app_version" "app_version_secondary" {
  count    = var.region == "us-east1" ? 1 : 0
  service  = "default"
  version_id = "v1"
  runtime   = "python39"
  entrypoint {
    shell = "gunicorn -w 2 -b :8080 main:app"
  }

  deployment { 
    zip {
      source_url = "https://storage.googleapis.com/hemtestbucket-hadr-us-east1/sample-app-us-east1.zip"
    }
  }
  service_account = google_service_account.app_engine_sa.email
}
