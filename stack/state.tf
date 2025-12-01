terraform {
  backend "s3" {
    # Bucket name is automatically determined by GitHub Actions workflow
    # Formula: fryrank-app-terraform-state-{account_id}
    # The bucket is provided via -backend-config=backend.hcl during terraform init
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}