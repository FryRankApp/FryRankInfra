provider "aws" {
  region = local.region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  name   = "fryrank-app"
  region = "us-west-2"
  account_id  = data.aws_caller_identity.current.account_id

  # Create terraform state bucket name based on account ID
  terraform_state_bucket_name = "${local.name}-terraform-state-${local.account_id}"

  tags = {
    Name       = local.name
    Repository = "https://github.com/FryRankApp/FryRankInfra"
    AccountId   = local.account_id
  }
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