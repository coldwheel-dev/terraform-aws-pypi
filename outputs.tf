output "cloudfront_pypi_index_url" {
  description = "The domain name of the CloudFront distribution"
  value       = module.pypi.cloudfront_pypi_index_url
}

output "index_url" {
  description = "The URL of the PEP 503 simple index, to pass to pip/uv as --index-url (uses the first custom domain when set)"
  value       = module.pypi.index_url
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (e.g. for /simple/* invalidations after uploads)"
  value       = module.pypi.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = module.pypi.cloudfront_distribution_arn
}

output "uploader_policy_json" {
  description = "IAM policy JSON for a CI identity that uploads packages and invalidates /simple/* (attach it to e.g. a GitHub Actions OIDC role)"
  value       = module.pypi.uploader_policy_json
}

output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = module.pypi.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.pypi.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = module.pypi.s3_bucket_domain_name
}

output "s3_bucket_policy" {
  description = "The bucket policy JSON attached by this module (merged with the optional deny policies for a created bucket)"
  value       = module.pypi.s3_bucket_policy
}

output "auth_secret_arn" {
  description = "The ARN of the Secrets Manager secret holding Basic Auth credentials (null when auth is disabled)"
  value       = module.pypi.auth_secret_arn
}

output "auth_secret_name" {
  description = "The name of the Secrets Manager secret holding Basic Auth credentials (null when auth is disabled)"
  value       = module.pypi.auth_secret_name
}

output "upload_url" {
  description = "The upload URL for twine (--repository-url), uv publish (--publish-url) and poetry (repositories.<name>.url); null when uploads are disabled"
  value       = module.pypi.upload_url
}

output "upload_secret_arn" {
  description = "The ARN of the Secrets Manager secret holding upload credentials (null when uploads are disabled)"
  value       = module.pypi.upload_secret_arn
}

output "upload_secret_name" {
  description = "The name of the Secrets Manager secret holding upload credentials (null when uploads are disabled)"
  value       = module.pypi.upload_secret_name
}
