provider "aws" {
  region = local.region
}

locals {
  name   = "fryrank-app"
  region = "us-west-2"
  account_id = data.aws_caller_identity.current.account_id

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/NickPriv/FryRankInfra"
  }
}