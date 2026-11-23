provider "aws" {
  region = "eu-central-1" # S3 bucket and Secrets Manager; Lambda@Edge is always deployed in us-east-1
}

module "pypi" {
  source = "../.."

  # Defaults: Basic Auth on, pypi.org fallback on, 7-day cooldown for new pypi.org releases
  upstream_cooldown_exclude = ["my-public-lib"]
}

output "index_url" {
  description = "Pass this to pip/uv as --index-url"
  value       = module.pypi.index_url
}

output "auth_secret_name" {
  description = "Put {\"user\": \"password\"} pairs into this secret"
  value       = module.pypi.auth_secret_name
}

output "s3_bucket_id" {
  description = "Upload packages here as <package-name>/<file>"
  value       = module.pypi.s3_bucket_id
}
