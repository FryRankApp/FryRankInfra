locals {
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