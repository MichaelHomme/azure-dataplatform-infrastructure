resource "random_string" "unique_suffix" {
  length  = 6
  special = false
  upper   = false
  lower   = true
}

resource "random_id" "suffix" {
  byte_length = 2
}
