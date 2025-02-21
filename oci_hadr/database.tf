resource "oci_database_db_system" "source_database" {
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  display_name         = "BaseDBSystem"
  shape                = var.db_system_shape
  subnet_id            = var.subnet_id
  admin_password       = var.admin_password
  database_edition     = "ENTERPRISE_EDITION"
  node_count           = 1
  license_model        = "LICENSE_INCLUDED"

  db_home {
    display_name     = "testDBHome"
    database {
      db_name             = var.db_name
      admin_password      = var.admin_password
      character_set       = "AL32UTF8"
      national_character_set = "AL16UTF16"
      db_workload         = "OLTP"
      pdb_name            = "pdb1"
    }
  }
}
