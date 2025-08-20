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

################################################################################
# DynamoDB Tables
################################################################################

output "rankings_table_name" {
  description = "The name of the rankings DynamoDB table"
  value       = aws_dynamodb_table.rankings.name
}

output "rankings_table_arn" {
  description = "The ARN of the rankings DynamoDB table"
  value       = aws_dynamodb_table.rankings.arn
}

output "user_metadata_table_name" {
  description = "The name of the user metadata DynamoDB table"
  value       = aws_dynamodb_table.user_metadata.name
}

output "user_metadata_table_arn" {
  description = "The ARN of the user metadata DynamoDB table"
  value       = aws_dynamodb_table.user_metadata.arn
}