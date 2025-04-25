################################################################################
# Terraform State Bucket
################################################################################

output "terraform_s3_bucket_id" {
  description = "The name of the bucket."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_id
}

output "terraform_s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_arn
}

output "terraform_s3_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_region
}