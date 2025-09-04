variable "aws_region" {
  description = "AWS region for the platform"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name for the platform"
  type        = string
  default     = "platform"
}

variable "instance_type" {
  description = "EC2 instance type for the platform"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB - sufficient for demo workloads
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access the platform (your IP)"
  type        = string
  default     = "173.63.251.175/32"  # Your current IP only
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the platform"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}
