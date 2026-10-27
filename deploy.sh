#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$ROOT_DIR/terraform"

for command in aws terraform uv python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

echo "Building Lambda deployment packages..."
bash "$ROOT_DIR/build.sh"

echo "Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init -input=false

if [[ "${CI:-}" == "true" ]]; then
  echo "Applying infrastructure (CI mode)..."
  terraform -chdir="$TERRAFORM_DIR" apply -input=false -auto-approve
else
  echo "Review the Terraform plan and approve the apply when prompted..."
  terraform -chdir="$TERRAFORM_DIR" apply -input=false
fi

api_url="$(terraform -chdir="$TERRAFORM_DIR" output -raw api_url)"
bucket_name="$(terraform -chdir="$TERRAFORM_DIR" output -raw website_bucket_name)"
distribution_id="$(terraform -chdir="$TERRAFORM_DIR" output -raw cloudfront_distribution_id)"
website_url="$(terraform -chdir="$TERRAFORM_DIR" output -raw website_url)"

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/groundwork-frontend.XXXXXX")"
trap 'rm -rf -- "$staging_dir"' EXIT

cp -R "$ROOT_DIR/app/frontend/." "$staging_dir/"
API_URL="$api_url" CONFIG_PATH="$staging_dir/config.js" python3 - <<'PY'
import json
import os
from pathlib import Path

api_url = os.environ["API_URL"]
config_path = Path(os.environ["CONFIG_PATH"])
config_path.write_text(
    "window.GROUNDWORK_CONFIG = {\n"
    f"  apiBaseUrl: {json.dumps(api_url)},\n"
    "};\n",
    encoding="utf-8",
)
PY

echo "Uploading frontend files to s3://$bucket_name..."
aws s3 sync "$staging_dir/" "s3://$bucket_name/" --delete

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --region us-east-1 \
  --distribution-id "$distribution_id" \
  --paths "/*"

echo "Deployment complete: $website_url"
