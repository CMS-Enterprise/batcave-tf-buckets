# S3 buckets for landing zone
resource "aws_s3_bucket" "landing_zone_buckets" {
  for_each      = toset(var.s3_bucket_names)
  bucket        = each.key
  force_destroy = var.force_destroy
  tags          = var.tags
}

locals {
  buckets = aws_s3_bucket.landing_zone_buckets
  #buckets = { for bucket in aws_s3_bucket.landing_zone_buckets : bucket.id => bucket }
}

resource "aws_s3_bucket_ownership_controls" "landing_zone_buckets" {
  for_each = aws_s3_bucket.landing_zone_buckets
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "landing_zone_buckets" {
  for_each = aws_s3_bucket.landing_zone_buckets
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = var.versioning_enabled ? aws_s3_bucket.landing_zone_buckets : {}
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  for_each = aws_s3_bucket.landing_zone_buckets
  bucket   = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "policy"
    Statement = concat([
      {
        Sid       = "EnforceTls"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${each.value.arn}/*",
          "${each.value.arn}",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "MinimumTlsVersion"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${each.value.arn}/*",
          "${each.value.arn}",
        ]
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      },
      ],
      "${var.extra_bucket_policies}",
      )
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = aws_s3_bucket.landing_zone_buckets
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_bucket_kms_key_id
      sse_algorithm     = var.sse_algorithm
    }
  }
}

# Lifecycle configuration for the dev buckets to remove all objects older than var.lifecycle_expiration_days.
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_expiration_days" {
  for_each = var.lifecycle_expiration_days > 0 ? aws_s3_bucket.landing_zone_buckets : {}

  bucket = each.value.id

  dynamic "rule" {
    for_each = var.lifecycle_expiration_days > 0 ? [1] : []

    content {
      id     = "delete-old-objects"
      status =  "Enabled"
      expiration {
       days = var.lifecycle_expiration_days
      }
      noncurrent_version_expiration {
       noncurrent_days = 1 
      }
    }
  }
}