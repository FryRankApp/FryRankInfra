terraform {
  backend "s3" {
    bucket = "fryrank-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}