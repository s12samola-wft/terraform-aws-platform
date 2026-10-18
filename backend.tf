terraform {
  backend "s3" {
    bucket       = "s12samola-terraform-aws-platform-tfstate"
    key          = "platform/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}