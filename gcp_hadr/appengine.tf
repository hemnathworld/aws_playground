# Create App Engine in each region
resource "google_app_engine_application" "app" {
  location_id = var.region
}

# Create a bucket to store app source code
resource "google_storage_bucket" "source_code" {
  name          = "${var.project_id}-app-source-code"
  location      = var.region
  force_destroy = true
}

# Upload app source code to Cloud Storage
resource "google_storage_bucket_object" "app_code" {
  name   = "sample_app.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${path.module}/sample_app"
}

resource "google_app_engine_standard_app_version" "app_version" {
  service  = "default"
  version_id = "v1"
  runtime   = "python310"
  entrypoint = "python main.py"

  deployment {
    zip {
      source = google_storage_bucket_object.app_code.source
    }
  }
}