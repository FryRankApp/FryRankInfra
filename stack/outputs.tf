################################################################################
# Terraform State Bucket
################################################################################

output "lambda_s3_bucket_id" {
  description = "The name of the bucket."
  value       = module.fryrank_lambda_function_bucket.s3_bucket_id
}

output "lambda_s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.fryrank_lambda_function_bucket.s3_bucket_arn
}

output "lambda_s3_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = module.fryrank_lambda_function_bucket.s3_bucket_region
}