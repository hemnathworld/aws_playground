resource "tls_private_key" "primary_instance_ssh_key" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "primary_private_key" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  content  = tls_private_key.primary_instance_ssh_key.private_key_pem
  filename = "${path.module}/primary_instance_private_key.pem"
  file_permission = "0600"
}

resource "oci_core_instance" "primary_vm" {
  count               = var.region == "us-luke-1" ? 1 : 0
  compartment_id      = var.compartment_id
  availability_domain = var.ad
  shape              = var.shape

  create_vnic_details {
    subnet_id = data.oci_core_subnet.external_subnet.id  # Fetching from another compartment
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  metadata = {
    ssh_authorized_keys =  [tls_private_key.primary_instance_ssh_key.public_key_openssh]
    user_data           = base64encode(file("scripts/us_west.sh"))
  }

  display_name = "primary-web-server"
  shape_config {
    ocpus = 2
    memory_in_gbs = 16
}
}

resource "oci_core_instance" "secondary_vm" {
  count               = var.region == "us-langley-1" ? 1 : 0
  compartment_id      = var.compartment_id
  availability_domain = var.ad
  shape              = var.shape

  create_vnic_details {
    subnet_id = var.subnet_id
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("scripts/us_east.sh"))
  }

  display_name = "secondary-web-server"
}
