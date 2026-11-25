# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Features

* Base module `frach/serverless-pypi-index/aws` 0.4.0: uploads with `twine upload`, `uv publish` and `poetry publish`. New inputs `upload_enabled` (off by default) and `upload_credentials`, new outputs `upload_url`, `upload_secret_arn` and `upload_secret_name`. Upload credentials are separate from the read credentials and existing files are never overwritten.

## [0.1.0] - 2026-11-23

### Features

* First version: wraps `frach/serverless-pypi-index/aws` 0.3.0 with Basic Auth, the pypi.org fallback and a 7-day upstream cooldown on by default.

[Unreleased]: https://github.com/coldwheel-dev/terraform-aws-pypi/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/coldwheel-dev/terraform-aws-pypi/releases/tag/v0.1.0
