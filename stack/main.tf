provider "aws" {
  region = local.region
}

locals {
  name   = "fryrank-app"
  region = "us-west-2"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/FryRankApp/FryRankInfra"
  }
}