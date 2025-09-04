# Golden Path Platform Infrastructure
# Deploys the platform itself on AWS using kind instead of EKS
# Demo trigger: $(date) - Testing end-to-end GitOps pipeline
# Workflow fix applied - should now deploy successfully
# Testing workflow trigger after duplication fix
# Testing real AWS deployment with OIDC authentication
# Testing OIDC permissions fix

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
  region = var.aws_region
  # No profile needed - GitHub Actions provides credentials via OIDC

  default_tags {
    tags = {
      Project     = "golden-path-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Use default VPC for simplicity (can be customized later)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for the platform cluster
resource "aws_security_group" "platform" {
  name_prefix = "golden-path-platform-"
  description = "Security group for Golden Path platform"
  vpc_id      = data.aws_vpc.default.id

  # SSH access - restricted to your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # Kubernetes API server - restricted to your IP only
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # HTTP/HTTPS for applications - restricted to your IP only
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # Jenkins - restricted to your IP only
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # Jenkins on port 8081 - restricted to your IP only
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # NodePort range for services - restricted to your IP only
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "golden-path-platform-sg"
  }
}

# Use existing IAM role and policy (already created)
# This avoids conflicts with existing resources
data "aws_iam_role" "platform_instance" {
  name = "golden-path-platform-instance-role"
}

data "aws_iam_policy" "platform_permissions" {
  name = "golden-path-platform-permissions"
}

data "aws_iam_instance_profile" "platform" {
  name = "golden-path-platform-profile"
}

# User data script to set up the platform
locals {
  user_data = base64encode(templatefile("${path.module}/user-data-simple.sh", {
    aws_region = var.aws_region
  }))
}

# Elastic IP for persistent IP address
resource "aws_eip" "platform" {
  domain = "vpc"

  tags = {
    Name = "golden-path-platform-eip"
    Type = "platform-cluster"
  }
}

# EC2 instance for the platform
resource "aws_instance" "platform" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = "golden-path-dev-new"

  vpc_security_group_ids = [aws_security_group.platform.id]
  subnet_id              = data.aws_subnets.default.ids[0]
  iam_instance_profile   = data.aws_iam_instance_profile.platform.name

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20 # Minimal space for demo platform (OS + Docker + Kind)
    encrypted   = true
  }

  tags = {
    Name = "golden-path-platform"
    Type = "platform-cluster"
  }
}

# Associate Elastic IP with the instance
resource "aws_eip_association" "platform" {
  instance_id   = aws_instance.platform.id
  allocation_id = aws_eip.platform.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
