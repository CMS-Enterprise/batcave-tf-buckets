variable "s3_bucket_names" {
  type    = list(string)
  default = []
}

variable "force_destroy" {
  default = true
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "s3_bucket_kms_key_id" {
  type        = string
  default     = "aws/s3"
  description = "KMS Key used to encrypt s3 buckets.  Defaults to aws/s3"
}
