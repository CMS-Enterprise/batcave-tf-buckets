terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.61.0"
    }
  }
  required_version = ">= 1.2"
}

resource "aws_s3_bucket" "landing_zone_buckets" {
  for_each      = toset(var.s3_bucket_names)
  bucket        = each.key
  force_destroy = var.force_destroy
  tags          = var.tags
}

locals {
}

resource "aws_s3_bucket_ownership_controls" "landing_zone_buckets" {
  ## Iterate over the list from var's to avoid some chicken/egg problems
  for_each = toset(var.s3_bucket_names)
  ## Refer to the id from the bucket resource to retain the dependency
  bucket = aws_s3_bucket.landing_zone_buckets[each.value].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "landing_zone_buckets" {
  ## Iterate over the list from var's to avoid some chicken/egg problems
  for_each = toset(var.s3_bucket_names)
  ## Refer to the id from the bucket resource to retain the dependency
  bucket = aws_s3_bucket.landing_zone_buckets[each.value].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  ## Iterate over the list from var's to avoid some chicken/egg problems
  for_each = var.versioning_enabled ? toset(var.s3_bucket_names) : []
  ## Refer to the id from the bucket resource to retain the dependency
  bucket = aws_s3_bucket.landing_zone_buckets[each.value].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "bucket" {
## Iterate over the list from var's to avoid some chicken/egg problems
for_each = toset(var.s3_bucket_names)
## Refer to the id from the bucket resource to retain the dependency
bucket = aws_s3_bucket.landing_zone_buckets[each.value].id

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
"${aws_s3_bucket.landing_zone_buckets[each.value].arn}/*",
aws_s3_bucket.landing_zone_buckets[each.value].arn,
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
"${aws_s3_bucket.landing_zone_buckets[each.value].arn}/*",
aws_s3_bucket.landing_zone_buckets[each.value].arn,
]
Condition = {
NumericLessThan = {
"s3:TlsVersion" = "1.2"
}
}
},
],
var.replication_permission_iam_role == null ? [] : [
{
Sid    = "ReplicaPermissionsFiles"
Effect = "Allow"
Principal = {
"AWS" : var.replication_permission_iam_role
}
Action = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
Resource = [
"${aws_s3_bucket.landing_zone_buckets[each.value].arn}/*",
]
},
{
Sid    = "ReplicaPermissions"
Effect = "Allow"
Principal = {
"AWS" : var.replication_permission_iam_role
}
Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
Resource = [
aws_s3_bucket.landing_zone_buckets[each.value].arn,
]
}
]
)
})
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
## Iterate over the list from var's to avoid some chicken/egg problems
for_each = toset(var.s3_bucket_names)
## Refer to the id from the bucket resource to retain the dependency
bucket = aws_s3_bucket.landing_zone_buckets[each.value].id

rule {
apply_server_side_encryption_by_default {
kms_master_key_id = var.s3_bucket_kms_key_id
sse_algorithm     = var.sse_algorithm
}
}
}

# Lifecycle configuration for the dev buckets to remove all objects older than var.lifecycle_expiration_days.
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_expiration_days" {
## Iterate over the list from var's to avoid some chicken/egg problems
for_each = var.lifecycle_expiration_days > 0 ? toset(var.s3_bucket_names) : []
## Refer to the id from the bucket resource to retain the dependency
bucket = aws_s3_bucket.landing_zone_buckets[each.value].id

dynamic "rule" {
for_each = var.lifecycle_expiration_days > 0 ? [1] : []

content {
id     = "delete-old-objects"
status = "Enabled"
expiration {
days = var.lifecycle_expiration_days
}
noncurrent_version_expiration {
noncurrent_days = 1
}
}
}
}
