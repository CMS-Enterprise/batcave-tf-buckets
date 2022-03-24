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
  default     = null
  description = "KMS Key used to encrypt s3 buckets.  Defaults to null, which uses default aws/s3 key"
}
