locals {
  lambda_bucket_name = "fryrank-lambda-function-bucket"
}

module "fryrank_lambda_function_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = local.lambda_bucket_name

  versioning = {
    status     = true
    mfa_delete = false
  }
}