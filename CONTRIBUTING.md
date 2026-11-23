# Contributing

This module only passes inputs through to
[frach/serverless-pypi-index/aws](https://github.com/frach/terraform-aws-serverless-pypi-index) and changes a few defaults.
Changes to how the index works belong there.

```bash
make install     # tflint, terraform-docs and the pre-commit hooks
make check       # pre-commit (fmt, docs, tflint, validate), terraform test
```

When the base module adds an input or output, add it to `variables.tf`, `main.tf` and `outputs.tf` with the same type,
default and description, bump `version` in `main.tf`, and add a line to `## [Unreleased]` in `CHANGELOG.md`.

## Releases

Versions follow [SemVer](https://semver.org) with `v`-prefixed tags.

1. On a `release/vX.Y.Z` branch, rename `## [Unreleased]` in `CHANGELOG.md` to `## [X.Y.Z] - YYYY-MM-DD`, add a fresh
   `## [Unreleased]` above it and update the links at the bottom. Open a PR and merge it once CI is green.
2. Tag the merge commit and push the tag: `git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z`.
3. The `Release` workflow publishes a GitHub Release from the `CHANGELOG.md` section, and the Terraform Registry picks up the tag.

By contributing you agree that your contributions are licensed under the [Apache 2.0 License](LICENSE).
