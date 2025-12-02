provider "aws" {
  region = local.region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  name        = "fryrank-app"
  region      = "us-west-2"
  account_id  = data.aws_caller_identity.current.account_id
  
  # Create terraform state bucket name based on account ID
  terraform_state_bucket_name = "${local.name}-terraform-state-${local.account_id}"
  
  # Construct the state bucket ARN directly (instead of using a data source)
  # to avoid Terraform trying to manage the bucket (which is managed by remote-state/)
  terraform_state_bucket_arn = "arn:aws:s3:::${local.terraform_state_bucket_name}"

  tags = {
    Name        = local.name
    Example     = local.name
    Repository  = "https://github.com/FryRankApp/FryRankInfra"
    AccountId   = local.account_id
  }
}