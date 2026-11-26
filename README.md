# terraform-aws-pypi

[![CI](https://github.com/coldwheel-dev/terraform-aws-pypi/actions/workflows/ci.yml/badge.svg)](https://github.com/coldwheel-dev/terraform-aws-pypi/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/coldwheel-dev/terraform-aws-pypi)](https://github.com/coldwheel-dev/terraform-aws-pypi/releases)
[![License](https://img.shields.io/github/license/coldwheel-dev/terraform-aws-pypi)](LICENSE)

Terraform module for a private PyPI index on AWS with a dependency cooldown. Your own packages are served from S3, everything
else comes from pypi.org, and new pypi.org releases are hidden for 7 days, so a compromised release is usually found and
removed before your builds can install it.

It is the free edition of [Coldwheel](https://coldwheel.dev) and a thin wrapper around
[frach/serverless-pypi-index/aws](https://registry.terraform.io/modules/frach/serverless-pypi-index/aws) with safer defaults.
All inputs and outputs are the same; only these defaults differ:

| Input | This module | Base module |
|---|---|---|
| `name` | `coldwheel` | `serverless-pypi-index` |
| `auth_enabled` | `true` | `false` |
| `upstream_enabled` | `true` | `false` |
| `upstream_cooldown_days` | `7` | `0` |

## Usage

```hcl
provider "aws" {
  region = "eu-central-1" # S3 bucket and Secrets Manager; Lambda@Edge is always deployed in us-east-1
}

module "pypi" {
  source  = "coldwheel-dev/pypi/aws"
  version = "~> 0.2"

  upstream_cooldown_exclude = ["my-public-lib"] # packages that skip the cooldown
}
```

After `terraform apply`, add users to the secret and point pip at the index:

```bash
aws secretsmanager put-secret-value --secret-id "$(terraform output -raw auth_secret_name)" \
  --secret-string '{"ci": "<password>"}'
pip install --index-url "https://ci:<password>@$(terraform output -raw cloudfront_pypi_index_url)/simple/" requests
```

Requires Terraform >= 1.5.7 or OpenTofu, and AWS provider >= 6.28.

## How the cooldown works

When pip asks for a package that isn't in your bucket, the index fetches the project from pypi.org's JSON API and leaves out
every file uploaded less than `upstream_cooldown_days` ago. pip, uv and Poetry then resolve to the newest release that is old
enough. Packages in your bucket and packages listed in `upstream_cooldown_exclude` are not affected. Set
`upstream_cooldown_days = 0` to turn it off.

Custom domains, authentication, uploads and client configuration are described in the
[base module's README](https://github.com/frach/terraform-aws-serverless-pypi-index#readme).

## Examples

- [basic](examples/basic): default deployment with Basic Auth, the pypi.org fallback and the cooldown.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_pypi"></a> [pypi](#module\_pypi) | frach/serverless-pypi-index/aws | 0.4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_auth_cache_ttl"></a> [auth\_cache\_ttl](#input\_auth\_cache\_ttl) | Number of seconds the Lambda functions cache credentials (read and upload) in memory before re-reading the secret. Credential changes take up to this long to propagate | `number` | `300` | no |
| <a name="input_auth_credentials"></a> [auth\_credentials](#input\_auth\_credentials) | Map of username => password stored in the Secrets Manager secret. Values end up in Terraform state; leave empty to populate the secret out-of-band as a JSON object of username/password pairs | `map(string)` | `{}` | no |
| <a name="input_auth_enabled"></a> [auth\_enabled](#input\_auth\_enabled) | Whether to protect the whole index (including package downloads) with HTTP Basic Authentication backed by AWS Secrets Manager | `bool` | `true` | no |
| <a name="input_auth_realm"></a> [auth\_realm](#input\_auth\_realm) | Realm advertised in the WWW-Authenticate challenge | `string` | `"Private PyPI"` | no |
| <a name="input_auth_secret_recovery_window_in_days"></a> [auth\_secret\_recovery\_window\_in\_days](#input\_auth\_secret\_recovery\_window\_in\_days) | Number of days Secrets Manager waits before deleting a credentials secret (read or upload). 0 forces immediate deletion | `number` | `7` | no |
| <a name="input_cloudfront_acm_certificate_arn"></a> [cloudfront\_acm\_certificate\_arn](#input\_cloudfront\_acm\_certificate\_arn) | ARN of an ACM certificate in us-east-1 covering every name in cloudfront\_aliases. When null, the default *.cloudfront.net certificate is used | `string` | `null` | no |
| <a name="input_cloudfront_aliases"></a> [cloudfront\_aliases](#input\_cloudfront\_aliases) | Custom domain names (CNAMEs) for the index, e.g. ["pypi.example.com"]. Requires cloudfront\_acm\_certificate\_arn | `list(string)` | `[]` | no |
| <a name="input_cloudfront_enabled"></a> [cloudfront\_enabled](#input\_cloudfront\_enabled) | Whether to create CloudFront distribution or not | `bool` | `true` | no |
| <a name="input_cloudfront_http_version"></a> [cloudfront\_http\_version](#input\_cloudfront\_http\_version) | HTTP version for CloudFront distribution | `string` | `"http2"` | no |
| <a name="input_cloudfront_logging_bucket"></a> [cloudfront\_logging\_bucket](#input\_cloudfront\_logging\_bucket) | Domain name of an S3 bucket for CloudFront standard access logs (e.g. "my-logs.s3.amazonaws.com"). The bucket must have ACLs enabled. When null, access logging is disabled | `string` | `null` | no |
| <a name="input_cloudfront_logging_prefix"></a> [cloudfront\_logging\_prefix](#input\_cloudfront\_logging\_prefix) | Prefix for CloudFront access log objects. When null, "<name>/" is used | `string` | `null` | no |
| <a name="input_cloudfront_minimum_protocol_version"></a> [cloudfront\_minimum\_protocol\_version](#input\_cloudfront\_minimum\_protocol\_version) | Minimum TLS version for viewers. Only enforced with a custom certificate; the default *.cloudfront.net certificate always allows TLSv1 | `string` | `"TLSv1.2_2025"` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | Price class for CloudFront distribution | `string` | `"PriceClass_100"` | no |
| <a name="input_cloudfront_response_headers_policy_id"></a> [cloudfront\_response\_headers\_policy\_id](#input\_cloudfront\_response\_headers\_policy\_id) | ID of a CloudFront response headers policy for every behavior. When null, the managed SecurityHeadersPolicy (HSTS, X-Content-Type-Options, X-Frame-Options, ...) is used | `string` | `null` | no |
| <a name="input_cloudfront_ttl_default"></a> [cloudfront\_ttl\_default](#input\_cloudfront\_ttl\_default) | Default TTL (seconds) for /simple/ index pages in CloudFront. Newly uploaded files show up in the index after at most this long | `number` | `300` | no |
| <a name="input_cloudfront_ttl_max"></a> [cloudfront\_ttl\_max](#input\_cloudfront\_ttl\_max) | Maximum TTL (seconds) for /simple/ index pages in CloudFront | `number` | `3600` | no |
| <a name="input_cloudfront_ttl_min"></a> [cloudfront\_ttl\_min](#input\_cloudfront\_ttl\_min) | Minimum TTL (seconds) for /simple/ index pages in CloudFront. Package files use the managed CachingOptimized policy | `number` | `0` | no |
| <a name="input_cloudfront_web_acl_id"></a> [cloudfront\_web\_acl\_id](#input\_cloudfront\_web\_acl\_id) | ARN of a WAFv2 web ACL (scope CLOUDFRONT, in us-east-1) to associate with the distribution, e.g. for rate limiting or IP allow-lists | `string` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Retention of the Lambda@Edge log group in us-east-1. Log groups that Lambda@Edge creates in other regions are not managed by this module | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Name (prefix) of the resources created by this module. Must be unique per AWS account, so the module can be deployed more than once | `string` | `"coldwheel"` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | ID of a Route 53 hosted zone in which to create A/AAAA alias records for every name in cloudfront\_aliases. When null, no DNS records are created | `string` | `null` | no |
| <a name="input_s3_acceleration_status"></a> [s3\_acceleration\_status](#input\_s3\_acceleration\_status) | Acceleration status of the bucket | `string` | `"Suspended"` | no |
| <a name="input_s3_acl"></a> [s3\_acl](#input\_s3\_acl) | Access control list for the bucket | `string` | `"private"` | no |
| <a name="input_s3_admin_principal_arns"></a> [s3\_admin\_principal\_arns](#input\_s3\_admin\_principal\_arns) | IAM principal ARNs granted full access (s3:*) to the bucket via the bucket policy. Usually unnecessary for same-account identities, whose IAM policies already grant access | `list(string)` | `[]` | no |
| <a name="input_s3_attach_deny_incorrect_encryption_headers"></a> [s3\_attach\_deny\_incorrect\_encryption\_headers](#input\_s3\_attach\_deny\_incorrect\_encryption\_headers) | Flag to attach deny incorrect encryption headers policy | `bool` | `false` | no |
| <a name="input_s3_attach_deny_incorrect_kms_key_sse"></a> [s3\_attach\_deny\_incorrect\_kms\_key\_sse](#input\_s3\_attach\_deny\_incorrect\_kms\_key\_sse) | Flag to attach deny incorrect KMS key SSE policy | `bool` | `false` | no |
| <a name="input_s3_attach_deny_insecure_transport_policy"></a> [s3\_attach\_deny\_insecure\_transport\_policy](#input\_s3\_attach\_deny\_insecure\_transport\_policy) | Flag to attach a bucket policy that denies requests not made over HTTPS | `bool` | `true` | no |
| <a name="input_s3_attach_deny_ssec_encrypted_object_uploads"></a> [s3\_attach\_deny\_ssec\_encrypted\_object\_uploads](#input\_s3\_attach\_deny\_ssec\_encrypted\_object\_uploads) | Flag to attach deny SSEC encrypted object uploads policy | `bool` | `false` | no |
| <a name="input_s3_attach_deny_unencrypted_object_uploads"></a> [s3\_attach\_deny\_unencrypted\_object\_uploads](#input\_s3\_attach\_deny\_unencrypted\_object\_uploads) | Flag to attach deny unencrypted object uploads policy | `bool` | `false` | no |
| <a name="input_s3_attach_require_latest_tls_policy"></a> [s3\_attach\_require\_latest\_tls\_policy](#input\_s3\_attach\_require\_latest\_tls\_policy) | Flag to attach require latest TLS policy | `bool` | `false` | no |
| <a name="input_s3_block_public_acls"></a> [s3\_block\_public\_acls](#input\_s3\_block\_public\_acls) | Flag to block public ACLs | `bool` | `true` | no |
| <a name="input_s3_block_public_policy"></a> [s3\_block\_public\_policy](#input\_s3\_block\_public\_policy) | Flag to block public policy | `bool` | `true` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the bucket. If s3\_create\_bucket is false, this must be the name of an existing bucket in the provider's region to be used as the origin for CloudFront distribution. Its bucket policy is replaced by this module | `string` | `null` | no |
| <a name="input_s3_control_object_ownership"></a> [s3\_control\_object\_ownership](#input\_s3\_control\_object\_ownership) | Flag to control object ownership | `bool` | `true` | no |
| <a name="input_s3_create_bucket"></a> [s3\_create\_bucket](#input\_s3\_create\_bucket) | Whether to create S3 bucket or not | `bool` | `true` | no |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | Flag to force destroy the bucket. When true, destroying the module deletes every package stored in it | `bool` | `false` | no |
| <a name="input_s3_ignore_public_acls"></a> [s3\_ignore\_public\_acls](#input\_s3\_ignore\_public\_acls) | Flag to ignore public ACLs | `bool` | `true` | no |
| <a name="input_s3_object_ownership"></a> [s3\_object\_ownership](#input\_s3\_object\_ownership) | Object ownership setting | `string` | `"BucketOwnerPreferred"` | no |
| <a name="input_s3_request_payer"></a> [s3\_request\_payer](#input\_s3\_request\_payer) | Request payer for the bucket | `string` | `"BucketOwner"` | no |
| <a name="input_s3_restrict_public_buckets"></a> [s3\_restrict\_public\_buckets](#input\_s3\_restrict\_public\_buckets) | Flag to restrict public buckets | `bool` | `true` | no |
| <a name="input_s3_versioning"></a> [s3\_versioning](#input\_s3\_versioning) | Versioning configuration for the bucket | <pre>object({<br/>    status     = bool<br/>    mfa_delete = bool<br/>  })</pre> | <pre>{<br/>  "mfa_delete": false,<br/>  "status": true<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags added to every resource that supports them | `map(string)` | `{}` | no |
| <a name="input_upload_credentials"></a> [upload\_credentials](#input\_upload\_credentials) | Map of username => password allowed to upload, stored in its own Secrets Manager secret (separate from `auth_credentials`). Values end up in Terraform state; leave empty to populate the secret out-of-band as a JSON object of username/password pairs | `map(string)` | `{}` | no |
| <a name="input_upload_enabled"></a> [upload\_enabled](#input\_upload\_enabled) | Whether to accept uploads from twine, uv publish and poetry publish at <index host>/upload/. Uploads need their own credentials (`upload_credentials`), never overwrite an existing file and invalidate the cached index pages. Files are limited to about 4 MB by the Lambda request size | `bool` | `false` | no |
| <a name="input_upstream_cooldown_days"></a> [upstream\_cooldown\_days](#input\_upstream\_cooldown\_days) | Hide upstream files uploaded less than this many days ago, so a freshly published (possibly malicious) release can't be installed until it has been public for a while. 0 disables the cooldown. Requires an upstream that serves PEP 691 JSON with PEP 700 upload times (pypi.org does) | `number` | `7` | no |
| <a name="input_upstream_cooldown_exclude"></a> [upstream\_cooldown\_exclude](#input\_upstream\_cooldown\_exclude) | Upstream package names that skip the cooldown, e.g. your own public packages or ones you need to patch quickly. Names are compared after PEP 503 normalization | `list(string)` | `[]` | no |
| <a name="input_upstream_enabled"></a> [upstream\_enabled](#input\_upstream\_enabled) | Whether to proxy /simple/<package>/ requests to the upstream index when the package is not hosted in the S3 bucket. Locally hosted packages always take precedence | `bool` | `true` | no |
| <a name="input_upstream_index_url"></a> [upstream\_index\_url](#input\_upstream\_index\_url) | HTTPS URL of the upstream PEP 503 simple index (e.g. https://pypi.org/simple) | `string` | `"https://pypi.org/simple"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_auth_secret_arn"></a> [auth\_secret\_arn](#output\_auth\_secret\_arn) | The ARN of the Secrets Manager secret holding Basic Auth credentials (null when auth is disabled) |
| <a name="output_auth_secret_name"></a> [auth\_secret\_name](#output\_auth\_secret\_name) | The name of the Secrets Manager secret holding Basic Auth credentials (null when auth is disabled) |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | The ARN of the CloudFront distribution |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | The ID of the CloudFront distribution (e.g. for /simple/* invalidations after uploads) |
| <a name="output_cloudfront_pypi_index_url"></a> [cloudfront\_pypi\_index\_url](#output\_cloudfront\_pypi\_index\_url) | The domain name of the CloudFront distribution |
| <a name="output_index_url"></a> [index\_url](#output\_index\_url) | The URL of the PEP 503 simple index, to pass to pip/uv as --index-url (uses the first custom domain when set) |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | The regional domain name of the S3 bucket |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The name of the S3 bucket |
| <a name="output_s3_bucket_policy"></a> [s3\_bucket\_policy](#output\_s3\_bucket\_policy) | The bucket policy JSON attached by this module (merged with the optional deny policies for a created bucket) |
| <a name="output_upload_secret_arn"></a> [upload\_secret\_arn](#output\_upload\_secret\_arn) | The ARN of the Secrets Manager secret holding upload credentials (null when uploads are disabled) |
| <a name="output_upload_secret_name"></a> [upload\_secret\_name](#output\_upload\_secret\_name) | The name of the Secrets Manager secret holding upload credentials (null when uploads are disabled) |
| <a name="output_upload_url"></a> [upload\_url](#output\_upload\_url) | The upload URL for twine (--repository-url), uv publish (--publish-url) and poetry (repositories.<name>.url); null when uploads are disabled |
| <a name="output_uploader_policy_json"></a> [uploader\_policy\_json](#output\_uploader\_policy\_json) | IAM policy JSON for a CI identity that uploads packages and invalidates /simple/* (attach it to e.g. a GitHub Actions OIDC role) |
<!-- END_TF_DOCS -->

## License

Apache 2.0, see [LICENSE](LICENSE).
