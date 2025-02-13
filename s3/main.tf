terraform {
  backend "s3" {
    bucket = "fryrank-terraform-state-bucket"
    key    = "s3/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = local.region
}

locals {
  region      = "us-west-2"
  bucket_name = "fryrank-terraform-state-bucket"
}

module "fryrank-terraform-state-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = local.bucket_name

  versioning = {
    status     = true
    mfa_delete = false
  }
}