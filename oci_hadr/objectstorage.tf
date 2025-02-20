
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
