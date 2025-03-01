resource "tls_private_key" "source_db_ssh_key" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "source_private_key" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  content  = tls_private_key.source_db_ssh_key.private_key_pem
  filename = "${path.module}/source_db_private_key.pem"
  file_permission = "0600"
}

resource "oci_database_db_system" "source_database" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  display_name         = "primary_database"
  shape                = var.db_system_shape
  subnet_id            = var.subnet_id
  admin_password       = var.admin_password
  database_edition     = "ENTERPRISE_EDITION"
  node_count           = 1
  license_model        = "LICENSE_INCLUDED"
  ssh_public_keys      = [tls_private_key.source_db_ssh_key.public_key_openssh]

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

resource "tls_private_key" "target_db_ssh_key" {
  count    = var.region == "us-langley-1" ? 1 : 0  ## East
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "target_private_key" {
  count    = var.region == "us-langley-1" ? 1 : 0  ## East
  content  = tls_private_key.source_db_ssh_key.private_key_pem
  filename = "${path.module}/source_db_private_key.pem"
  file_permission = "0600"
}

resource "oci_database_db_system" "target_database" {
  count    = var.region == "us-langley-1" ? 1 : 0  ## West
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  display_name         = "Secondary_Database"
  shape                = var.db_system_shape
  subnet_id            = var.subnet_id
  admin_password       = var.admin_password
  database_edition     = "ENTERPRISE_EDITION"
  node_count           = 1
  license_model        = "LICENSE_INCLUDED"
  ssh_public_keys      = [tls_private_key.source_db_ssh_key.public_key_openssh]

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
