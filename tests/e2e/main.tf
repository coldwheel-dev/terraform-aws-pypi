# Root module used by scripts/e2e.sh to deploy this wrapper from the checkout into a real AWS account, with the wrapper's
# own defaults (auth, pypi.org fallback, 7-day cooldown) plus uploads. State is local and ignored by git.

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  default_tags {
    tags = {
      Purpose = "coldwheel-pypi-e2e"
    }
  }
}

module "pypi" {
  source = "../.."

  # Its own name, so it can run next to the base module's e2e deployment in the same account
  name = "coldwheel-e2e"

  # The suite expects six to skip the cooldown (it checks the page is proxied from pypi.org as is)
  upstream_cooldown_exclude = ["six"]

  upload_enabled                      = true
  auth_secret_recovery_window_in_days = 0
  cloudfront_ttl_default              = 5
  s3_force_destroy                    = true

  # Fixed name, so the CI role (aws-foundations, github-e2e) can be limited to the e2e buckets
  s3_bucket_name = "coldwheel-e2e-${data.aws_caller_identity.current.account_id}"
}

output "index_url" {
  value = module.pypi.index_url
}

output "upload_url" {
  value = module.pypi.upload_url
}

output "auth_secret_name" {
  value = module.pypi.auth_secret_name
}

output "upload_secret_name" {
  value = module.pypi.upload_secret_name
}

output "cloudfront_distribution_id" {
  value = module.pypi.cloudfront_distribution_id
}
