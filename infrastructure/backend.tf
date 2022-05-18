terraform {
  required_version = ">=1.1.9"
  backend "s3" {
    key = "terraform.tfstate"
    encrypt = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.13.0"
    }
  }
}
