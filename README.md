# FryRankInfra
Terraform-defined infrastructure for FryRank.

## How to Run Terraform
1. Run `terraform init` to initialize the Terraform configuration.
2. Run `terraform get` to download the necessary modules after a new module is added.
3. Run `terraform plan` to see what changes will be made.
4. After the code is merged, `terraform apply` will automatically be run to apply the changes.