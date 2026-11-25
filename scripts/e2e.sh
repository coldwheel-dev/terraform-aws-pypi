#!/usr/bin/env bash
# End-to-end test: deploys this wrapper from the checkout into a real AWS account and runs the base module's pytest
# suite (tests/e2e/suite of frach/terraform-aws-serverless-pypi-index, from the tag of the pinned base version) against
# it: auth, uploads, PEP 503 pages, the cooldown on the real pypi.org, pip/uv/poetry/twine. Then tears everything down.
#
# Usage:  scripts/e2e.sh [run|up|test|down]     (default: run = up + test + down)
#         Usually through make (make e2e, make e2e-test, make e2e-destroy), which sets AWS_PROFILE and AWS_REGION.
#
# Needs: terraform (or TF=tofu), aws CLI v2, curl, python3 >= 3.9, and AWS credentials for a test account.
# Costs a few cents. KEEP=1 skips the teardown after `run`. PYTEST_ARGS="-k upload" runs part of the suite.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E2E_DIR="$ROOT/tests/e2e"
TF="${TF:-terraform}"
export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-central-1}}"

# The suite comes from the base module at the version main.tf pins
BASE_REPO="frach/terraform-aws-serverless-pypi-index"
BASE_VERSION="$(sed -n 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"\([0-9.]*\)".*/\1/p' "$ROOT/main.tf" | head -1)"
COOLDOWN_DAYS="$(awk '/variable "upstream_cooldown_days"/,/^}/' "$ROOT/variables.tf" | sed -n 's/^[[:space:]]*default[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p')"

E2E_USER="e2e"
E2E_PASSWORD="${E2E_PASSWORD:-e2e-$(python3 -c 'import secrets; print(secrets.token_hex(8))')}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
tf() { "$TF" -chdir="$E2E_DIR" "$@"; }
out() { tf output -raw "$1"; }

# Stop before anything else (including the teardown) when there are no usable AWS credentials, e.g. an expired SSO login
need_aws() {
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    printf '\033[31mNo valid AWS credentials for profile %s.\033[0m Log in first, e.g.:\n  aws sso login --profile %s\n' \
      "${AWS_PROFILE:-default}" "${AWS_PROFILE:-<profile>}" >&2
    exit 1
  fi
}

up() {
  log "Checking AWS credentials"
  aws sts get-caller-identity --query '[Account, Arn]' --output text

  log "Deploying the wrapper to $AWS_REGION"
  tf init -input=false -upgrade >/dev/null
  tf apply -input=false -auto-approve

  log "Setting test credentials in Secrets Manager"
  aws secretsmanager put-secret-value --secret-id "$(out auth_secret_name)" \
    --secret-string "{\"$E2E_USER\": \"$E2E_PASSWORD\"}" >/dev/null
  aws secretsmanager put-secret-value --secret-id "$(out upload_secret_name)" \
    --secret-string "{\"$E2E_USER\": \"upload-$E2E_PASSWORD\"}" >/dev/null
  printf '%s' "$E2E_PASSWORD" >"$E2E_DIR/.e2e-password"

  log "Waiting for CloudFront to finish deploying (usually 5-15 minutes)"
  aws cloudfront wait distribution-deployed --id "$(out cloudfront_distribution_id)"
}

run_tests() {
  log "Fetching the end-to-end suite of $BASE_REPO v$BASE_VERSION"
  mkdir -p "$WORK/base"
  curl -sSfL "https://codeload.github.com/$BASE_REPO/tar.gz/refs/tags/v$BASE_VERSION" |
    tar -xz -C "$WORK/base" --strip-components=1

  log "Installing the test clients (pytest, twine, uv, poetry)"
  python3 -m venv "$WORK/venv"
  "$WORK/venv/bin/pip" -q install --upgrade pip
  "$WORK/venv/bin/pip" -q install -r "$WORK/base/tests/e2e/requirements.txt"

  log "Running the suite (no fake upstream: the cooldown is checked against pypi.org only)"
  E2E_PASSWORD="$(cat "$E2E_DIR/.e2e-password")"
  PATH="$WORK/venv/bin:$PATH" \
    E2E_INDEX_URL="$(out index_url)" \
    E2E_USER="$E2E_USER" \
    E2E_PASSWORD="$E2E_PASSWORD" \
    E2E_UPLOAD_URL="$(out upload_url)" \
    E2E_UPLOAD_PASSWORD="upload-$E2E_PASSWORD" \
    E2E_COOLDOWN_DAYS="$COOLDOWN_DAYS" \
    "$WORK/venv/bin/python" -m pytest "$WORK/base/tests/e2e/suite" -p no:cacheprovider -ra ${PYTEST_ARGS:-}
}

down() {
  log "Destroying the test deployment"
  if tf destroy -input=false -auto-approve; then
    rm -f "$E2E_DIR/.e2e-password"
    return 0
  fi
  cat <<EOT

Destroy didn't finish. This is expected for Lambda@Edge: AWS deletes the function's edge replicas
a few hours after the CloudFront distribution is gone, and only then can the function be deleted.
Everything else is already removed. Finish the cleanup later with:

  make e2e-destroy
EOT
  return 1
}

[[ "${1:-run}" =~ ^(run|up|down)$ ]] && need_aws

case "${1:-run}" in
  up) up ;;
  test) run_tests ;;
  down) down ;;
  run)
    # Tear down even when the deployment fails half-way, so no partial resources are left behind
    set +e
    (
      set -e
      up
    )
    status=$?
    if ((status == 0)); then
      run_tests
      status=$?
    fi
    if [[ "${KEEP:-0}" == "1" ]]; then
      log "KEEP=1: leaving the deployment up. Remove it with: make e2e-destroy"
    else
      down || true
    fi
    exit "$status"
    ;;
  *)
    echo "Usage: $0 [run|up|test|down]" >&2
    exit 2
    ;;
esac
