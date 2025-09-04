# Terraform backend configuration for shared state
terraform {
  backend "s3" {
    bucket         = "golden-path-platform-terraform-state"
    key            = "platform/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "golden-path-platform-terraform-locks"
    encrypt        = true
  }
}
