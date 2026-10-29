# R2 object storage (free tier: 10 GB-month, 1M Class A / 10M Class B ops, free egress).
# Buckets default to the Standard storage class, which is the only class with a free tier.
# The API token needs "Account > Workers R2 Storage > Edit".

variable "account_id" {
  description = "Cloudflare account ID (dashboard > right sidebar on any zone overview)"
  sensitive   = true
}

variable "r2_bucket_name" {
  description = "R2 bucket name (lowercase letters, numbers, hyphens; 3-63 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.r2_bucket_name))
    error_message = "Bucket name must be 3-63 chars: lowercase letters, numbers, hyphens; cannot start or end with a hyphen."
  }
}

variable "r2_location" {
  description = "Location hint: WNAM, ENAM, WEUR, EEUR, APAC, OC"
  default     = "ENAM"
}

resource "cloudflare_r2_bucket" "assets" {
  account_id = var.account_id
  name       = var.r2_bucket_name
  location   = var.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

output "r2_bucket_name" {
  value = cloudflare_r2_bucket.assets.name
}

output "r2_s3_endpoint" {
  value     = "https://${var.account_id}.r2.cloudflarestorage.com"
  sensitive = true
}
