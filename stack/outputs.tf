################################################################################
# Private Repository
################################################################################

output "repository_name" {
  description = "Name of the repository"
  value       = module.ecr.repository_name
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = module.ecr.repository_arn
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = module.ecr.repository_registry_id
}

output "repository_url" {
  description = "The URL of the repository (in the form `aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`)"
  value       = module.ecr.repository_url
}

################################################################################
# Terraform State Bucket
################################################################################

output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = module.fryrank-terraform-state-bucket.s3_bucket_region
}