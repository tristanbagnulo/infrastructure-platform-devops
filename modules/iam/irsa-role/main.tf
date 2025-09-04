locals {
  role_name   = "${var.app}-${var.env}-irsa"
  common_tags = merge({ App = var.app, Env = var.env, ManagedBy = "golden-platform" }, var.tags)
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { type = "Federated" identifiers = [var.oidc_provider_arn] }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.app}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "combined" {
  # S3 access (rw to objects, list bucket)
  dynamic "statement" {
    for_each = var.grants.s3
    content {
      actions   = ["s3:PutObject","s3:GetObject","s3:DeleteObject"]
      resources = ["${statement.value}/*"]
    }
  }
  dynamic "statement" {
    for_each = var.grants.s3
    content {
      actions   = ["s3:ListBucket"]
      resources = [statement.value]
    }
  }

  # SQS (send/receive, delete, change visibility)
  dynamic "statement" {
    for_each = var.grants.sqs
    content {
      actions   = ["sqs:SendMessage","sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueAttributes","sqs:ChangeMessageVisibility"]
      resources = [statement.value]
    }
  }

  # DynamoDB (rw basic)
  dynamic "statement" {
    for_each = var.grants.dynamodb
    content {
      actions   = ["dynamodb:PutItem","dynamodb:GetItem","dynamodb:DeleteItem","dynamodb:UpdateItem","dynamodb:Query","dynamodb:Scan","dynamodb:BatchWriteItem"]
      resources = [statement.value]
    }
  }

  # RDS Secrets (for database access via secrets manager)
  dynamic "statement" {
    for_each = var.grants.rds_secrets
    content {
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = [statement.value]
    }
  }

  # Application Secrets (for API keys, etc.)
  dynamic "statement" {
    for_each = var.grants.secrets
    content {
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = [statement.value]
    }
  }

  # Always add SSM parameter access for application configuration
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters", 
      "ssm:GetParametersByPath"
    ]
    resources = ["arn:aws:ssm:*:*:parameter/apps/${var.env}/${var.app}/*"]
  }
}

# Only create policy if there are actually grants to manage
resource "aws_iam_policy" "this" {
  count  = length(concat(var.grants.s3, var.grants.sqs, var.grants.dynamodb, var.grants.rds_secrets, var.grants.secrets)) > 0 ? 1 : 0
  name   = "${local.role_name}-policy"
  policy = data.aws_iam_policy_document.combined.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = length(aws_iam_policy.this) > 0 ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}
