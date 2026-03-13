# FryRankInfra
Terraform-defined infrastructure for FryRank.

## Getting Started
Shared environments are managed by GitHub Actions to prevent local development from interfering with existing infrastructure (state is stored in S3).

For sandbox testing / local iteration, use the repo helper scripts (`deploy.sh` / `deploy.bat`) rather than running `terraform plan` / `terraform apply` directly. The scripts handle required environment variables and let you pass through Terraform flags (like `-auto-approve`).

Note: `TerraformDev` IAM credentials allow `terraform plan` but not `terraform apply`. For sandbox applies you may need an admin role.

## First time startup instructions
Since we use s3 to store the terraform state, but we need the s3 bucket to access the state to run terraform, this is a
chicken and egg problem. The first time the infrastructure in this repo is initialized, the following steps should
be followed:
1. `cd remote-state`
2. Run `terraform init`
3. Run `terraform plan`
4. After the code is merged, `terraform apply` will automatically be run to apply the changes.

## Deploying Infrastructure (Recommended)
1. Obtain AWS access key and secret access key for your sandbox account from the AWS Log In portal. Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
2. Use the helper scripts from the repo root:
   - Plan: `./deploy.sh --plan` or `deploy.bat --plan`
   - Apply: `./deploy.sh --apply` or `deploy.bat --apply` (default)
   - Passing Terraform args: `./deploy.sh --apply -auto-approve`

For Beta/Prod, use GitHub (open a PR to view a plan; merge to apply).

`deploy.sh` / `deploy.bat` auto-discover the CloudFront Web ACL ARN, export `TF_VAR_cloudfront_web_acl_arn`, and then run Terraform.

## Steps to set up your sandbox account

1. Copy AWS access credentials from AWS login portal to authenticate with AWS in your terminal
2. Run `terraform apply` on remote-state to bootstrap the terraform state in your account
3. Switch to the `stack` directory. Create the `backend.hcl` file inside the stack directory following the example in `backend.hcl.example`
4. Run `terraform init "-backend-config=backend.hcl"` to initialize your state, with the proper bucket name
5. Add the following AWS Systems Manager parameters to the us-west-2 (Oregon) region. Copy all of the values from the Beta account.
   - GOOGLE_API_KEY (SecureString)
   - GOOGLE_AUTH_KEY (SecureString)
   - DATABASE_URI (SecureString)
   - BACKEND_SERVICE_PATH (String)
6. Set `create_lambdas` to false in `lambda.tf`.
7. From the repo root, deploy the stack with `./deploy.sh --apply` (or `deploy.bat --apply`). You may need `deploy.sh --apply -auto-approve` / `./deploy.sh --apply -auto-approve` depending on how you run the script.
8. [For full-stack testing only] Update the Lambda package (filename `Constants.java`) so that your CloudFront URL is set as an allowed origin in the CORS configuration.
9. Build the Lambda package and upload the zip to the  `fryrank-app-lambda-function-bucket-[YOUR_ACCOUNT_ID]`. (Zip file location: `FryRankLambda/build/distributions/FryRankLambda.zip`)
10. Re-run `./deploy.sh --apply` (or `deploy.bat --apply`) with `create_lambdas` set to true to deploy the Lambdas
11. [For full-stack testing only] Update `BACKEND_SERVICE_PATH` .env var in FryRankFrontend to the API Gateway deployed endpoint and build the frontend (`npm run build`).
12. Upload your frontend to S3 by running the command `aws s3 cp [YOUR_PATH_HERE]/FryRankFrontend/build s3://fryrank-app-spa-bucket-[YOUR_ACCOUNT_ID_HERE]/ --recursive`
13. Request to have the Cloudfront domain allowlisted in the Google Cloud UI for Google Auth
14. Start testing, either via your CloudFront URL or by calling API Gateway directly (from the console or CLI)

### What's not included in the sandbox testing process
- Right now, the frontend and backend pipelines are not connected to GitHub. The deployments currently take place manually by building locally and uploading the build artifacts to S3, as described above. This may be changed in the future to facilitate the local testing process.
- Terraform apply on your sandbox account will not be run by GitHub actions. It will be run manually using your admin role received when you log in to AWS.

## Testing AppSpec Generation (for Lambda Deployment)
To test the OpenAPI specification generation for API Gateway:

1. Navigate to the `/test` directory
2. Run `python test_generate_appspec.py` to generate and validate the OpenAPI specification
3. The script will generate a new OpenAPI specification file
