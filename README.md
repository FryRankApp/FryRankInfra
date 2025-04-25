# FryRankInfra
Terraform-defined infrastructure for FryRank.

## First time startup instructions

Since we use s3 to store the terraform state, but we need the s3 bucket to access the state to run terraform, this is a
chicken and egg problem. The first time the infrastructure in this repo is initialized, the following steps should
be followed:
1. `cd remote-state`
2. Run `terraform init`
3. Run `terraform plan`
4. Run `teraform apply`

## How to Run Terraform
1. Run `terraform init` to initialize the Terraform configuration.
2. Run `terraform get` to download the necessary modules after a new module is added.
3. Run `terraform plan` to see what changes will be made.
4. After the code is merged, `terraform apply` will automatically be run to apply the changes.