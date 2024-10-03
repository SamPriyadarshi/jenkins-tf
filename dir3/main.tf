terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Or the latest version
    }
  }
}

resource "random_id" "test" {
  byte_length = 12
}

output "random_id" {
  value = random_id.test.hex
}
