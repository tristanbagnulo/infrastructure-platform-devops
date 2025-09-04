locals {
  common_tags = merge(
    {
      App       = var.app
      Env       = var.env
      ManagedBy = "golden-platform"
      Purpose   = var.purpose
    },
    var.tags
  )
  
  bucket_name = "${var.app}-${var.name}-${var.env}"
  
  # Storage class mapping based on access pattern
  storage_class_transitions = var.access_pattern == "frequent" ? {
    ia_days     = 30
    glacier_days = 90
  } : var.access_pattern == "infrequent" ? {
    ia_days     = 1  # Immediate IA
    glacier_days = 30
  } : {
    ia_days     = 1
    glacier_days = 1  # Immediate Glacier for archive
  }
}

# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.env == "dev" ? true : false  # Allow force destroy in dev
  tags          = local.common_tags
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption (always enabled for security)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true  # Reduce KMS costs
  }
}

# Public access blocking (secure by default)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = !var.public_access
  block_public_policy     = !var.public_access
  ignore_public_acls      = !var.public_access
  restrict_public_buckets = !var.public_access
}

# Lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  depends_on = [aws_s3_bucket_versioning.this]
  bucket     = aws_s3_bucket.this.id

  rule {
    id     = "lifecycle-rule"
    status = "Enabled"

    # Current version transitions
    dynamic "transition" {
      for_each = var.access_pattern != "frequent" ? [] : [1]
      content {
        days          = local.storage_class_transitions.ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.purpose != "static_website" ? [1] : []
      content {
        days          = local.storage_class_transitions.glacier_days
        storage_class = "GLACIER"
      }
    }

    # Non-current version management
    dynamic "noncurrent_version_transition" {
      for_each = var.versioning ? [1] : []
      content {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }
    }

    # Expiration
    expiration {
      days = var.retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS configuration for web applications
resource "aws_s3_bucket_cors_configuration" "this" {
  count  = var.cors_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = var.purpose == "static_website" ? ["GET"] : ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]  # Customize based on your domains
    max_age_seconds = 3000
  }
}

# Website configuration for static hosting
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.purpose == "static_website" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket policy for static website
resource "aws_s3_bucket_policy" "website" {
  count  = var.purpose == "static_website" && var.public_access ? 1 : 0
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Notification configuration (placeholder for future integration)
resource "aws_s3_bucket_notification" "this" {
  count  = 0  # Enable when integrating with SQS/SNS
  bucket = aws_s3_bucket.this.id
}
