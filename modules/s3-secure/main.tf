locals {
  common_tags = merge(
    { App = var.app, Env = var.env, ManagedBy = "golden-platform" },
    var.tags
  )
  bucket_name = "${var.app}-${var.name}-${var.env}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = false
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = var.versioning ? "Enabled" : "Suspended" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  restrict_public_buckets = var.block_public_access
  ignore_public_acls      = var.block_public_access
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "expire-after-days"
    status = "Enabled"
    expiration { days = var.lifecycle_days }
  }
}

# Optional server access logs (to itself off by default; for prod, point to a central log bucket)
resource "aws_s3_bucket_logging" "this" {
  count         = var.server_access_logs ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.this.id
  target_prefix = "logs/"
}
