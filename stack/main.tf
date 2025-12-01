provider "aws" {
  region = local.region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  name        = "fryrank-app"
  region      = var.region
  account_id  = data.aws_caller_identity.current.account_id
  
  # Create terraform state bucket name based on account ID
  terraform_state_bucket_name = "${local.name}-terraform-state-${local.account_id}"

  tags = {
    Name        = local.name
    Example     = local.name
    Repository  = "https://github.com/FryRankApp/FryRankInfra"
    AccountId   = local.account_id
  }
}