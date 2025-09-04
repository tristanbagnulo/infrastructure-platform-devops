# Multi-Account Permission Boundaries for Golden Path Platform
# Implements the 4-layer governance model described in the docs

# Permission boundary for platform service accounts
resource "aws_iam_policy" "platform_permission_boundary" {
  name        = "GoldenPathPlatformBoundary"
  description = "Permission boundary for Golden Path platform service accounts"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow platform to manage infrastructure resources
        Effect = "Allow"
        Action = [
          # S3 management within approved patterns
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucket*",
          "s3:ListBucket*",
          "s3:PutBucket*",
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject*",
          
          # RDS management within approved patterns  
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDB*",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:AddTagsToResource",
          
          # Secrets Manager
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          
          # SSM Parameter Store
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DeleteParameter",
          "ssm:DescribeParameters",
          "ssm:AddTagsToResource",
          
          # IAM for IRSA roles (limited)
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:TagRole",
          "iam:TagPolicy",
          
          # EC2 for networking (read-only)
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNetworkAcls"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = ["us-east-2"]  # Restrict to approved regions
          }
        }
      },
      {
        # Require specific tags on all resources
        Effect = "Deny"
        Action = [
          "s3:CreateBucket",
          "rds:CreateDBInstance",
          "secretsmanager:CreateSecret",
          "iam:CreateRole"
        ]
        Resource = "*"
        Condition = {
          "Null" = {
            "aws:RequestTag/ManagedBy" = "true"
          }
        }
      },
      {
        # Prevent modification of permission boundaries
        Effect = "Deny"
        Action = [
          "iam:CreateRole",
          "iam:PutRolePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "iam:PermissionsBoundary" = "arn:aws:iam::*:policy/GoldenPathPlatformBoundary"
          }
        }
      },
      {
        # Deny access to production-like resources in dev
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "rds:db-instance-class" = [
              "db.r6g.*",
              "db.r5.*", 
              "db.m6i.large",
              "db.m6i.xlarge",
              "db.m6i.2xlarge"
            ]
          }
        }
      }
    ]
  })
  
  tags = {
    ManagedBy = "golden-path-platform"
    Purpose   = "permission-boundary"
  }
}

# Application permission boundary (for IRSA roles)
resource "aws_iam_policy" "application_permission_boundary" {
  name        = "GoldenPathApplicationBoundary"
  description = "Permission boundary for application IRSA roles"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow applications to access only their own resources
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*-${var.app_name}-*",
          "arn:aws:s3:::*-${var.app_name}-*/*"
        ]
      },
      {
        # RDS access limited to app-specific databases
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:*:*:dbuser:${var.app_name}-*/*"
        ]
      },
      {
        # Secrets access limited to app-specific secrets
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:${var.app_name}/*"
        ]
      },
      {
        # SSM Parameter access limited to app namespace
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/${var.app_name}/*"
        ]
      },
      {
        # Deny all other actions
        Effect = "Deny"
        NotAction = [
          "s3:GetObject",
          "s3:PutObject", 
          "s3:DeleteObject",
          "s3:ListBucket",
          "rds-db:connect",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    ManagedBy = "golden-path-platform"
    Purpose   = "application-boundary"
  }
}

variable "app_name" {
  description = "Application name for resource scoping"
  type        = string
  default     = "*"
}
