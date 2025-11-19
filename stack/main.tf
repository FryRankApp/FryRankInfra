provider "aws" {
  region = local.region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  name        = "fryrank-app"
  region      = var.region
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  
  # Create unique naming prefix
  name_prefix = "${local.name}-${local.environment}-${local.account_id}"

  tags = {
    Name        = local.name
    Example     = local.name
    Repository  = "https://github.com/FryRankApp/FryRankInfra"
    Environment = local.environment
    AccountId   = local.account_id
  }
}