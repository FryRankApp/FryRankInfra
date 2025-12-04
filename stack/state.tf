terraform {
  backend "s3" {
    # Bucket name is dynamically determined based on AWS account ID
    # Formula: fryrank-app-terraform-state-{account_id}
    # 
    # IMPORTANT: This placeholder will cause terraform init to fail until you provide
    # the correct bucket name via -backend-config=backend.hcl
    # 
    # For GitHub Actions: The bucket is automatically provided via -backend-config=backend.hcl
    # For manual/developer runs: 
    #   1. Get your account ID: aws sts get-caller-identity --query Account --output text
    #   2. Create backend.hcl: echo 'bucket = "fryrank-app-terraform-state-YOUR-ACCOUNT-ID"' > backend.hcl
    #   3. Run: terraform init -backend-config=backend.hcl
    # 
    # See backend.hcl.example for a template
    bucket = "MUST-BE-OVERRIDDEN-VIA-BACKEND-CONFIG"  # Invalid - will fail until backend.hcl is provided
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}