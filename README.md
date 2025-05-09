# FryRankInfra
Terraform-defined infrastructure for FryRank.

## Getting Started
All infrastructure is managed by Github Actions only to prevent local development testing from
interfering with existing infrastructure since the state is stored in s3. All developers must use
the `TerraformDev` IAM credentials to authenticate which allows for the use of `terraform plan` but
not `terraform apply`.

## First time startup instructions
Since we use s3 to store the terraform state, but we need the s3 bucket to access the state to run terraform, this is a
chicken and egg problem. The first time the infrastructure in this repo is initialized, the following steps should
be followed:
1. `cd remote-state`
2. Run `terraform init`
3. Run `terraform plan`
4. After the code is merged, `terraform apply` will automatically be run to apply the changes.

## How to Run Terraform
1. Obtain AWS access key and secret access key for development from vault. Export `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` respectively. This will allow your local instance of terraform to access
existing FryRank infrastructure.
2. Run `terraform init` to initialize the Terraform configuration.
3. Run `terraform get` to download the necessary modules after a new module is added.
4. Run `terraform plan` to see what changes will be made.
5. After the code is merged, `terraform apply` will automatically be run to apply the changes.

## Testing AppSpec Generation (for Lambda Deployment)
To test the OpenAPI specification generation for API Gateway:

1. Navigate to the `/test` directory
2. Run `python test_generate_appspec.py` to generate and validate the OpenAPI specification
3. The script will generate a new OpenAPI specification file
