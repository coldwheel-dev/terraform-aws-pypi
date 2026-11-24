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

Versions follow [SemVer](https://semver.org) with `v`-prefixed tags; before `1.0.0`, breaking changes bump the minor version.

Two commands. First list everything that goes out under
`## [Unreleased]` in `CHANGELOG.md` on `main`.

1. `make release VERSION=X.Y.Z` on `main`: makes the `release/vX.Y.Z` branch, turns `## [Unreleased]` into
   `## [X.Y.Z] - YYYY-MM-DD` with a fresh `## [Unreleased]` above it, updates the compare links at the bottom and
   `version = "~> X.Y"` in the README snippets, commits, pushes and prints the pull request link. Merge it once CI is green.
2. `make release-tag`: switches to `main`, pulls the merge and pushes the tag `vX.Y.Z`. The `Release` workflow publishes a
   GitHub Release with that version's `CHANGELOG.md` section as its notes. The Terraform Registry picks up the new tag
   automatically.

By contributing you agree that your contributions are licensed under the [Apache 2.0 License](LICENSE).
