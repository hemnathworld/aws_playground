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

# Create App Engine in each region
resource "google_app_engine_application" "app" {
  location_id = var.region
}


# Upload app source code to Cloud Storage
resource "google_storage_bucket_object" "app_code" {
  name   = "sample-app.zip"
  bucket = google_storage_bucket.primary_bucket.name
  source = "${path.module}/sample-app.zip"
}

resource "google_app_engine_standard_app_version" "app_version_primary" {
  count    = var.region == "us-west1" ? 1 : 0
  service  = "default"
  version_id = "v1"
  runtime   = "python39"
  entrypoint {
    shell = "python main_us-west1.py"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/hemtestbucket-hadr-us-west1/sample-app.zip"
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
    shell = "python main_us-east1.py"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/hemtestbucket-hadr-us-west1/sample-app.zip"
    }
  }
  service_account = google_service_account.app_engine_sa.email
}
