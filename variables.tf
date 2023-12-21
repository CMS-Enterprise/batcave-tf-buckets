variable "s3_bucket_names" {
  type    = list(string)
  default = []
}

variable "force_destroy" {
  default = true
  type    = bool
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

variable "sse_algorithm" {
  type        = string
  default     = "aws:kms"
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms, defaults to aws:kms."
}

variable "lifecycle_expiration_days" {
  type        = number
  default     = "0"
  description = "Number of days for object lifecycle to expire the objects in dev env.  Defaults to 0, which disables the rule"
}

variable "versioning_enabled" {
  type    = bool
  default = false
}

variable "replication_permission_iam_role" {
  type    = string
  default = null
}
