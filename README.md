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
1. Obtain AWS access key and secret access key for your sandbox account from the AWS Log In portal. Export `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` respectively. This will allow your local instance of terraform to access the account.
2. Run `terraform init` to initialize the Terraform configuration.
3. Run `terraform get` to download the necessary modules after a new module is added.
4. `terraform plan`:
    - In your sandbox account, this will show the changes to be made to your infrastructure.
    - To see the changes to be made to the Beta account, create the PR in GitHub
5. `terraform apply`:
    - In your sandbox account, this will apply the changes to your infrastructure.
    - To apply the changes to the Beta account, merge the PR in GitHub

## Steps to set up your sandbox account

1. Copy AWS access credentials from AWS login portal to authenticate with AWS in your terminal
2. Run `terraform apply` on remote-state to bootstrap the terraform state in your account
3. Create the `backend.hcl` file inside the stack directory following the example in `backend.hcl.example`
4. Run `terraform init "-backend-config=backend.hcl"` to initialize your state, with the proper bucket name
5. Add the following AWS Systems Manager parameters. the values don't matter; they are only used for auto deployments (see note below). the values themselves will still be set in the .env file locally.
   - GOOGLE_API_KEY (SecureString)
   - GOOGLE_AUTH_KEY (SecureString)
   - DATABASE_URI (SecureString)
   - BACKEND_SERVICE_PATH
6. Set `create_lambdas` to false in `lambda.tf`.
7. Run `terraform apply`
8. Build the Lambda package and upload the zip to the  `fryrank-app-lambda-function-bucket-[YOUR_ACCOUNT_ID]`. (Zip file location: `FryRankLambda/build/distributions/FryRankLambda.zip`)
9. Re-run `terraform apply` with `create_lambdas` set to true to deploy the Lambdas
10. Update `BACKEND_SERVICE_PATH` .env var in FryRankFrontend to the API Gateway deployed endpoint and build the frontend (`npm run dev`).
11. Upload your frontend to S3 by running the command `aws s3 cp [YOUR_PATH_HERE]/FryRankFrontend/build s3://fryrank-app-spa-bucket-[YOUR_ACCOUNT_ID_HERE]/ --recursive`
12. Start testing, either via your CloudFront URL or by calling API Gateway directly (from the console or CLI)

### What's not included in the sandbox testing process
- Right now, the frontend and backend pipelines are not connected to GitHub. The deployments currently take place manually by building locally and uploading the build artifacts to S3, as described above. This may be changed in the future to facilitate the local testing process.
- Terraform apply on your sandbox account will not be run by GitHub actions. It will be run manually using your admin role received when you log in to AWS.

## Testing AppSpec Generation (for Lambda Deployment)
To test the OpenAPI specification generation for API Gateway:

1. Navigate to the `/test` directory
2. Run `python test_generate_appspec.py` to generate and validate the OpenAPI specification
3. The script will generate a new OpenAPI specification file
