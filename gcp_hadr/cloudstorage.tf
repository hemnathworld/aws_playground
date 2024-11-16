resource "google_storage_bucket" "primary_bucket" {
  name     = var.bucket_name
  location = "US"
  storage_class = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
  lifecycle_rule {
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 30
    }
  }

  custom_placement_config {
    data_locations = ["us-west1", "us-east1"]
  }

  force_destroy = true 
}

resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = google_storage_bucket.primary_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
