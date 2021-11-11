provider "aws" {
  region  = var.region

  default_tags = local.default_tags
}
