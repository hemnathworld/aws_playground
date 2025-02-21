
data "oci_objectstorage_namespace" "ns" {}

resource "oci_objectstorage_bucket" "source_bucket" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  region         = var.region
  storage_tier   = "Standard"
}

resource "oci_objectstorage_bucket" "target_bucket" {
  count    = var.region == "us-langley-1" ? 1 : 0  ## East 
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  region         = var.region
  storage_tier   = "Standard"
}

resource "oci_identity_policy" "replication_policy" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  name           = var.bucket_policy_name
  description    = "Policy to allow object storage replication across regions"
  compartment_id = var.compartment_id

  statements = [
    "allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_id}"
  ]
}

resource "oci_objectstorage_replication_policy" "replication_policy" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  bucket = var.bucket_name
  destination_region = var.target_region
  destination_bucket = var.target_bucket_name
  name              = "cross-region-replication"
  namespace         = data.oci_objectstorage_namespace.ns.namespace
}
