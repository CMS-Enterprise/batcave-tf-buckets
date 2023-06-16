output "s3_buckets" {
  value = aws_s3_bucket.landing_zone_buckets
}

output "bucket_verisioning" {
  value = aws_s3_bucket_versioning.bucket_versioning
}
