data "google_storage_project_service_account" "gcs_account" {}

resource "google_storage_bucket" "primary_bucket" {
  count    = var.region == "us-west1" ? 1 : 0
  name     = var.source_bucket_name
  location = var.region
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
  force_destroy = true 
}

resource "google_pubsub_topic" "my_topic" {
  count    = var.region == "us-west1" ? 1 : 0
  name    = var.topic_name
  project = var.source_project_id
}

resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  count    = var.region == "us-west1" ? 1 : 0
  topic  = google_pubsub_topic.my_topic[count.index].name
  role   = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  ]
}

resource "google_project_iam_member" "grant_pubsub_subscriber" {
  count    = var.region == "us-west1" ? 1 : 0
  project = var.source_project_id  # Project A
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:project-${var.target_project_number}@storage-transfer-service.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "transfer_subscription" {
  count    = var.region == "us-west1" ? 1 : 0
  name  = var.subscriber_name
  topic = "projects/${var.source_project_id}/topics/${var.topic_name}"
  ack_deadline_seconds = 20
}

resource "google_storage_notification" "storage_notification" {
  count    = var.region == "us-west1" ? 1 : 0
  bucket         = google_storage_bucket.primary_bucket[count.index].name
  topic          = google_pubsub_topic.my_topic[count.index].id
  payload_format = "JSON_API_V1"
  event_types = [
    "OBJECT_FINALIZE",   # Trigger when a new object is created
    "OBJECT_METADATA_UPDATE"  # Trigger when metadata is updated
  ]
  depends_on = [google_pubsub_topic_iam_binding.pubsub_binding]
}

resource "google_storage_bucket" "secondary_bucket" {
  count    = var.region == "us-east1" ? 1 : 0
  name     = var.target_bucket_name
  location = var.region
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
  force_destroy = true 
}

resource "google_storage_transfer_job" "storage_transfer" {
  count    = var.region == "us-east1" ? 1 : 0
  description = "Storage Transfer Job"
  project = var.target_project_id

  transfer_spec {
    gcs_data_source {
      bucket_name = var.source_bucket_name # Replace with your source bucket
    }

    gcs_data_sink {
      bucket_name = var.target_bucket_name  # Replace with your destination bucket
    }

    transfer_options {
      delete_objects_unique_in_sink = false
    }
  }

  # Event-driven trigger using Pub/Sub
  event_stream {
    name = "projects/${var.source_project_id}/subscriptions/${var.subscriber_name}"
  }
} 
