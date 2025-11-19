# Multi-Account Deployment Guide

This Terraform configuration has been updated to support deployment across multiple AWS accounts and environments.

## Key Changes Made

### 1. Environment Variables
- Added `environment` variable (dev, staging, prod)
- Added `region` variable (configurable)
- Added `terraform_state_bucket_name` variable
- Added `account_id` data source for unique naming

### 2. Naming Convention
Resources use different naming patterns based on AWS requirements:

**Globally Unique Resources (S3 buckets):**
- Pattern: `${app-name}-${environment}-${account-id}-${resource-type}`
- Example: `fryrank-app-dev-123456789012-lambda-function-bucket`

**Account-Scoped Resources (API Gateway, DynamoDB, IAM):**
- Pattern: `${app-name}-${environment}-${resource-type}`
- Examples: 
  - API Gateway: `fryrank-app-dev-api`
  - DynamoDB: `fryrank-app-dev-user-metadata`
  - IAM roles: `fryrank-app-dev-lambda-execution-role`

### 3. Environment-Specific SSM Parameters
SSM parameters now use environment-specific paths:
- `/dev/DATABASE_URI`
- `/prod/GOOGLE_API_KEY`
- `/staging/BACKEND_SERVICE_PATH`

## Deployment Instructions

### 1. Set up SSM Parameters
Before deploying, create the required SSM parameters for your environment:

```bash
# For dev environment
aws ssm put-parameter --name "/dev/DATABASE_URI" --value "your-database-uri" --type "String"
aws ssm put-parameter --name "/dev/GOOGLE_API_KEY" --value "your-google-api-key" --type "SecureString"
aws ssm put-parameter --name "/dev/GOOGLE_AUTH_KEY" --value "your-google-auth-key" --type "SecureString"
aws ssm put-parameter --name "/dev/BACKEND_SERVICE_PATH" --value "your-backend-path" --type "String"

# For prod environment
aws ssm put-parameter --name "/prod/DATABASE_URI" --value "your-database-uri" --type "String"
aws ssm put-parameter --name "/prod/GOOGLE_API_KEY" --value "your-google-api-key" --type "SecureString"
aws ssm put-parameter --name "/prod/GOOGLE_AUTH_KEY" --value "your-google-auth-key" --type "SecureString"
aws ssm put-parameter --name "/prod/BACKEND_SERVICE_PATH" --value "your-backend-path" --type "String"
```

### 2. Deploy to Different Environments

#### Deploy to Dev Environment
```bash
terraform init -backend-config="key=fryrank-dev/terraform.tfstate"
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

#### Deploy to Staging Environment
```bash
terraform init -backend-config="key=fryrank-staging/terraform.tfstate"
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
```

#### Deploy to Prod Environment
```bash
terraform init -backend-config="key=fryrank-prod/terraform.tfstate"
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

### 3. Backend Configuration
Update your backend configuration to use environment-specific state files:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "fryrank-${var.environment}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Resource Naming Examples

After deployment, your resources will have names like:

### Dev Environment (Account: 123456789012)
- S3 Bucket: `fryrank-app-dev-123456789012-lambda-function-bucket` (globally unique)
- API Gateway: `fryrank-app-dev-api` (account-scoped)
- DynamoDB Table: `fryrank-app-dev-user-metadata` (account-scoped)
- Lambda Function: `getAllReviews` (function names remain the same for API compatibility)

### Prod Environment (Account: 987654321098)
- S3 Bucket: `fryrank-app-prod-987654321098-lambda-function-bucket` (globally unique)
- API Gateway: `fryrank-app-prod-api` (account-scoped)
- DynamoDB Table: `fryrank-app-prod-user-metadata` (account-scoped)
- Lambda Function: `getAllReviews` (function names remain the same for API compatibility)

## Benefits

1. **Global Uniqueness**: S3 bucket names are now globally unique across all AWS accounts
2. **Environment Separation**: Clear separation between dev, staging, and prod environments
3. **Account Isolation**: Resources are isolated by AWS account ID
4. **Scalable**: Easy to add new environments or accounts
5. **Maintainable**: Consistent naming convention across all resources

## Migration Notes

If you have existing resources, you'll need to:
1. Update your SSM parameters to use the new environment-specific paths
2. Recreate resources with the new naming convention
3. Update any hardcoded references in your application code
4. Update your CI/CD pipelines to use the new environment variables
