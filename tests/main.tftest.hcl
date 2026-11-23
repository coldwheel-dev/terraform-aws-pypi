# Unit tests with mocked providers: no AWS credentials or resources needed.
# Run with `make tf-test` (requires Terraform >= 1.7).

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "eu-central-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  # OpenTofu fills computed attributes with random strings, so ARNs that the provider validates need real-looking values
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/coldwheel-edge-router" }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-east-1:123456789012:function:coldwheel-edge-router"
      qualified_arn = "arn:aws:lambda:us-east-1:123456789012:function:coldwheel-edge-router:1"
    }
  }
  mock_resource "aws_secretsmanager_secret" {
    defaults = { arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:coldwheel-credentials-abc" }
  }
}

run "defaults" {
  command = apply

  assert {
    condition     = var.auth_enabled && var.upstream_enabled && var.upstream_cooldown_days == 7
    error_message = "Auth, the pypi.org fallback and a 7-day cooldown must be on by default."
  }

  assert {
    condition     = output.auth_secret_arn != null
    error_message = "The credentials secret must be created by default."
  }
}

run "opt_out" {
  command = apply

  variables {
    auth_enabled           = false
    upstream_cooldown_days = 0
  }

  assert {
    condition     = output.auth_secret_arn == null
    error_message = "No secret must be created without auth."
  }
}

run "cooldown_must_be_whole_days" {
  command = plan

  variables {
    upstream_cooldown_days = 1.5
  }

  expect_failures = [var.upstream_cooldown_days]
}
