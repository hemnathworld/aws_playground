resource "aws_dynamodb_table" "customer_table" {
  count    = var.region == "us-west-1" ? 1 : 0
  name     = var.dynamodb_table_name
  stream_enabled = false
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "customer_id"
    type = "S"  # or "N" if using a number
  }

  attribute {
    name = "address"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "phone_number"
    type = "S"
  }

  hash_key = "customer_id"

  # Define Global Secondary Indexes for unused attributes
  global_secondary_index {
    name            = "NameIndex"
    hash_key        = "name"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "AddressIndex"
    hash_key        = "address"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "PhoneNumberIndex"
    hash_key        = "phone_number"
    projection_type = "ALL"
  }

  replica {
    region_name = "us-east-1"
  }
}
