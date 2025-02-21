resource "tls_private_key" "db_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.db_ssh_key.private_key_pem
  filename = "${path.module}/db_private_key.pem"
  file_permission = "0600"
}

resource "oci_database_db_system" "source_database" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  display_name         = "BaseDBSystem"
  shape                = var.db_system_shape
  subnet_id            = var.subnet_id
  admin_password       = var.admin_password
  database_edition     = "ENTERPRISE_EDITION"
  node_count           = 1
  license_model        = "LICENSE_INCLUDED"
  ssh_public_keys      = [tls_private_key.db_ssh_key.public_key_openssh]

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
