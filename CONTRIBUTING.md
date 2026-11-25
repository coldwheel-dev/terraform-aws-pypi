# Contributing

This module only passes inputs through to
[frach/serverless-pypi-index/aws](https://github.com/frach/terraform-aws-serverless-pypi-index) and changes a few defaults.
Changes to how the index works belong there.

```bash
make install     # tflint, terraform-docs and the pre-commit hooks
make check       # pre-commit (fmt, docs, tflint, validate), terraform test, parity with the base module
make e2e         # deploy to a sandbox account, run the base module's end-to-end suite, destroy
```

When the base module adds an input or output, add it to `variables.tf`, `main.tf` and `outputs.tf` with the same type,
default and description, bump `version` in `main.tf`, and add a line to `## [Unreleased]` in `CHANGELOG.md`. `make parity` (also in CI) fails until
every input and output of the pinned version is passed through with the same type, default and description; only `name`,
`auth_enabled`, `upstream_enabled` and `upstream_cooldown_days` may have other defaults.

## End-to-end test

`make e2e` deploys the wrapper from your checkout to the maintainers' sandbox account (`E2E_PROFILE=coldwheel-nonprod`,
`E2E_REGION=eu-central-1`; override both for your own) with its own defaults plus uploads, and runs the pytest suite from
`tests/e2e/suite` of the base module at the pinned version: auth, uploads, the PEP 503 pages, the cooldown against pypi.org,
and pip, uv, Poetry and twine. The exact cooldown tests need the base module's fake upstream and are skipped here; they run in
the base module's own `make e2e`. A few cents, 15-20 minutes. `make e2e KEEP=1` keeps the deployment and
`make e2e-test PYTEST_ARGS="-k upload"` re-runs part of the suite. Lambda@Edge can only be deleted a few hours after its
distribution, so finish a stuck teardown later with `make e2e-destroy`.

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
