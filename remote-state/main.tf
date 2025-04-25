provider "aws" {
  region = local.region
}

locals {
  name   = "fryrank-app"
  region = "us-west-2"

  tags = {
    Name       = local.name
    Repository = "https://github.com/FryRankApp/FryRankInfra"
  }
  terraform_state_bucket_name = "fryrank-terraform-state-bucket"
}

module "fryrank-terraform-state-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = local.terraform_state_bucket_name

  versioning = {
    status     = true
    mfa_delete = false
  }
}