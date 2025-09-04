variable "app" {
  description = "Application name"
  type        = string
}

variable "env" {
  description = "Environment (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.env)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be created"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the kind cluster"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM - good for kind
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
}

variable "disk_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30  # Enough for Docker images and kind cluster
}

# Environment-specific sizing
locals {
  instance_types = {
    dev   = "t3.medium"   # 2 vCPU, 4GB - $0.0416/hour
    stage = "t3.large"    # 2 vCPU, 8GB - $0.0832/hour  
    prod  = "t3.xlarge"   # 4 vCPU, 16GB - $0.1664/hour
  }
  
  disk_sizes = {
    dev   = 30  # 30GB
    stage = 50  # 50GB
    prod  = 100 # 100GB
  }
}
