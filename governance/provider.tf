terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "sso-dev"

  default_tags {
    tags = {
      Project     = "golden-path-governance"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
