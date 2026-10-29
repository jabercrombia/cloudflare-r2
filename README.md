# Cloudflare Terraform

Terraform configuration for managing Cloudflare DNS records and R2 object storage.

---

# Layout

```
infra/
  main.tf                     # provider + DNS records
  r2.tf                       # R2 bucket + outputs
  terraform.tfvars.example    # variables to fill in locally
```

---

# Goals

* Terraform is the single source of truth
* No manual changes in the Cloudflare dashboard
* Zero state drift
* Predictable, reviewable changes via `plan`

---

# Prerequisites

* Terraform >= 1.5
* A Cloudflare API token with:
  * `Zone > DNS > Edit` for the zone
  * `Account > Workers R2 Storage > Edit` for the account
* Your zone ID and account ID (dashboard → right sidebar on any zone overview)

---

# Setup

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Fill in `terraform.tfvars`:

```hcl
cloudflare_api_token = "..."
zone_id              = "..."
account_id           = "..."
```

`terraform.tfvars` is gitignored. Never commit it.

Then:

```bash
terraform init
terraform plan
terraform apply
```

Never skip `plan`.

---

# Provider

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
```

---

# DNS

Managed in `infra/main.tf`:

| Record | Type  | Proxied |
| ------ | ----- | ------- |
| `@`    | CNAME | yes     |
| `www`  | CNAME | yes     |
| `blog` | A ×2  | no      |

Rules:

* Use CNAME (flattened by Cloudflare) for root and `www`
* Don't mix A and CNAME records on the same name
* Avoid wildcard (`*`) records unless explicitly needed

---

# R2 Storage

Managed in `infra/r2.tf`.

| Variable         | Default               | Notes                                  |
| ---------------- | --------------------- | -------------------------------------- |
| `r2_bucket_name` | `jabercrombia-assets` | lowercase, numbers, hyphens; 3–63 chars |
| `r2_location`    | `ENAM`                | WNAM, ENAM, WEUR, EEUR, APAC, OC       |

* Bucket uses the Standard storage class (the only class with a free tier: 10 GB-month, 1M Class A / 10M Class B ops, free egress)
* `prevent_destroy` is set, so Terraform will refuse to delete the bucket

Outputs:

```bash
terraform output r2_bucket_name
terraform output -raw r2_s3_endpoint   # https://<account_id>.r2.cloudflarestorage.com
```

---

# State

Use a remote backend (S3, Terraform Cloud, etc.) to avoid local state loss. State files are gitignored.

---

# Verification

```bash
dig jabercrombia.com
dig www.jabercrombia.com
dig blog.jabercrombia.com
curl -I https://www.jabercrombia.com   # expect server: cloudflare
```

---

# Troubleshooting

## Redirect loops

Set Cloudflare SSL/TLS mode to **Full (strict)**.

## State drift

Caused by manual dashboard changes.

```bash
terraform state list
terraform apply -refresh-only
```

## R2 permission errors

Make sure the API token includes `Account > Workers R2 Storage > Edit`.

---

# Golden Rules

* Terraform owns DNS and storage
* Cloudflare dashboard is read-only
* Always `plan` before `apply`
